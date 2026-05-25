#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import unicodedata
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "KadomaGomi" / "Resources" / "Data"
SCHEMA_DIR = ROOT / "Schemas"
RESOURCE_MASTER_PATH = ROOT / "KadomaGomi" / "Resources" / "initial_master_27223_2026.json"
DOCS_MASTER_PATH = ROOT / "docs" / "kadoma_27223_2026_master.json"
MANIFEST_PATH = ROOT / "docs" / "manifest.json"

SPLIT_FILES = {
    "categories": DATA_DIR / "garbage_categories.json",
    "items": DATA_DIR / "garbage_items.json",
    "areas": DATA_DIR / "collection_areas.json",
    "schedules": DATA_DIR / "collection_schedule.json",
    "special": DATA_DIR / "special_rules.json",
}

SCHEMA_FILES = {
    "categories": SCHEMA_DIR / "garbage_category.schema.json",
    "items": SCHEMA_DIR / "garbage_item.schema.json",
    "areas": SCHEMA_DIR / "collection_area.schema.json",
    "schedules": SCHEMA_DIR / "collection_schedule.schema.json",
    "special": SCHEMA_DIR / "special_rules.schema.json",
    "master": SCHEMA_DIR / "master.schema.json",
}

EXPECTED_AREA_IDS = {"A", "B", "C", "D", "E", "F"}
EXPECTED_SCHEDULE_CATEGORIES = {
    "burnable",
    "plastic_container",
    "bottles_cans",
    "paper_cloth",
    "small_items",
    "pet_bottle",
    "bulky",
}
DATE_FORMAT = "%Y-%m-%d"
MIN_ITEM_COUNT = 200
CONFIDENCE_STATUSES = {"confirmed", "needs_review", "estimated"}


def load_json(path: Path) -> Any:
    try:
        with path.open("r", encoding="utf-8") as fh:
            return json.load(fh)
    except FileNotFoundError:
        raise ValueError(f"{path} が見つかりません")
    except json.JSONDecodeError as exc:
        raise ValueError(f"{path} のJSONが不正です: {exc}")


def dump_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2, sort_keys=False) + "\n"


def parse_date(value: str, label: str, errors: list[str]) -> datetime | None:
    try:
        return datetime.strptime(value, DATE_FORMAT)
    except ValueError:
        errors.append(f"{label}: 日付は YYYY-MM-DD 形式で指定してください: {value!r}")
        return None


def normalize_text(value: str) -> str:
    text = unicodedata.normalize("NFKC", value).lower()
    text = re.sub(r"\s+", "", text)
    text = text.replace("ごみ", "ゴミ")
    text = text.replace("ー", "").replace("-", "").replace("・", "").replace("/", "")
    return "".join(chr(ord(ch) + 0x60) if "ぁ" <= ch <= "ゖ" else ch for ch in text)


def _type_matches(value: Any, expected_type: str) -> bool:
    if expected_type == "object":
        return isinstance(value, dict)
    if expected_type == "array":
        return isinstance(value, list)
    if expected_type == "string":
        return isinstance(value, str)
    if expected_type == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if expected_type == "number":
        return isinstance(value, (int, float)) and not isinstance(value, bool)
    if expected_type == "boolean":
        return isinstance(value, bool)
    if expected_type == "null":
        return value is None
    return True


def validate_against_schema(value: Any, schema: dict[str, Any], path: str = "$") -> list[str]:
    errors: list[str] = []
    expected = schema.get("type")
    if expected is not None:
        allowed = expected if isinstance(expected, list) else [expected]
        if not any(_type_matches(value, kind) for kind in allowed):
            errors.append(f"{path}: 型が不正です。期待={allowed}, 実際={type(value).__name__}")
            return errors

    if "enum" in schema and value not in schema["enum"]:
        errors.append(f"{path}: 許可されていない値です: {value!r}")

    if isinstance(value, dict):
        for key in schema.get("required", []):
            if key not in value:
                errors.append(f"{path}.{key}: 必須項目がありません")
        for key, child_schema in schema.get("properties", {}).items():
            if key in value:
                errors.extend(validate_against_schema(value[key], child_schema, f"{path}.{key}"))

    if isinstance(value, list):
        if len(value) < schema.get("minItems", 0):
            errors.append(f"{path}: 配列要素が不足しています")
        item_schema = schema.get("items")
        if item_schema:
            for index, item in enumerate(value):
                errors.extend(validate_against_schema(item, item_schema, f"{path}[{index}]"))

    if isinstance(value, str):
        if len(value) < schema.get("minLength", 0):
            errors.append(f"{path}: 空文字は使えません")
        if "pattern" in schema and re.search(schema["pattern"], value) is None:
            errors.append(f"{path}: パターンに一致しません: {value!r}")

    if isinstance(value, (int, float)) and not isinstance(value, bool):
        if "minimum" in schema and value < schema["minimum"]:
            errors.append(f"{path}: 最小値を下回っています: {value}")
        if "maximum" in schema and value > schema["maximum"]:
            errors.append(f"{path}: 最大値を上回っています: {value}")

    return errors


def validate_schema_files(data: dict[str, Any]) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    for key in ("categories", "items", "areas", "schedules", "special"):
        schema = load_json(SCHEMA_FILES[key])
        errors.extend(validate_against_schema(data[key], schema, f"split.{key}"))
    return errors, warnings


def _duplicates(values: list[str]) -> list[str]:
    return sorted(value for value, count in Counter(values).items() if count > 1)


def validate_relationships(data: dict[str, Any]) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    categories = data["categories"]
    items = data["items"]
    areas = data["areas"]
    schedules = data["schedules"]
    special = data["special"]

    category_ids = {category["id"] for category in categories}
    area_ids = {area["id"] for area in areas}
    item_ids = [item["id"] for item in items]
    schedule_ids = [schedule["id"] for schedule in schedules]

    if len(items) < MIN_ITEM_COUNT:
        errors.append(f"検索辞書は最低{MIN_ITEM_COUNT}件必要です。現在={len(items)}")

    if duplicates := _duplicates([category["id"] for category in categories]):
        errors.append(f"カテゴリIDが重複しています: {', '.join(duplicates)}")
    if duplicates := _duplicates(item_ids):
        errors.append(f"品目IDが重複しています: {', '.join(duplicates)}")
    if duplicates := _duplicates([area["id"] for area in areas]):
        errors.append(f"地区IDが重複しています: {', '.join(duplicates)}")
    if duplicates := _duplicates(schedule_ids):
        errors.append(f"収集ルールIDが重複しています: {', '.join(duplicates)}")

    if area_ids != EXPECTED_AREA_IDS:
        errors.append(f"A-F全地区が必要です。現在={sorted(area_ids)}")

    for category in categories:
        if len(category.get("disposalSteps", [])) < 3:
            errors.append(f"{category['id']}: カテゴリの出し方ステップは3件以上必要です")
        if not category.get("examples"):
            errors.append(f"{category['id']}: 代表品目 examples が必要です")
        if category.get("confidenceStatus") not in CONFIDENCE_STATUSES:
            errors.append(f"{category['id']}: confidenceStatus が不正です: {category.get('confidenceStatus')}")
        if category.get("confidenceStatus") != "confirmed" and not category.get("requiresOfficialCheck", False):
            errors.append(f"{category['id']}: confirmed以外は requiresOfficialCheck=true が必要です")
        if not str(category.get("sourceUrl", "")).startswith("https://www.city.kadoma.osaka.jp/"):
            errors.append(f"{category['id']}: sourceUrl は門真市公式URLが必要です: {category.get('sourceUrl')}")
        parse_date(category.get("updatedAt", ""), f"{category['id']}.updatedAt", errors)

    item_names: dict[str, list[str]] = defaultdict(list)
    alias_index: dict[str, list[str]] = defaultdict(list)
    for item in items:
        if item["categoryId"] not in category_ids:
            errors.append(f"{item['id']}: 存在しないカテゴリを参照しています: {item['categoryId']}")
        for name in item["names"]:
            item_names[normalize_text(name)].append(item["id"])
        for alias in item.get("aliases", []):
            alias_index[normalize_text(alias)].append(item["id"])
        if item["confidence"] < 0.6:
            warnings.append(f"{item['id']}: confidence が低いためUIで公式確認推奨表示が必要です")
        if item.get("confidenceStatus") not in CONFIDENCE_STATUSES:
            errors.append(f"{item['id']}: confidenceStatus が不正です: {item.get('confidenceStatus')}")
        if item.get("confidenceStatus") != "confirmed" and not item.get("requiresOfficialCheck", False):
            errors.append(f"{item['id']}: confirmed以外は requiresOfficialCheck=true が必要です")
        if item.get("confidenceStatus") == "estimated":
            warnings.append(f"{item['id']}: estimated は確定表示せず公式確認推奨表示が必要です")
        if len(item.get("disposalSteps", [])) < 2:
            errors.append(f"{item['id']}: disposalSteps は2件以上必要です")
        if item.get("requiresReservation") and item["categoryId"] != "bulky":
            warnings.append(f"{item['id']}: 予約が必要な非粗大ごみ品目です。UIで公式確認を促してください")
        if not str(item.get("sourceUrl", "")).startswith("https://www.city.kadoma.osaka.jp/"):
            warnings.append(f"{item['id']}: sourceUrl は門真市公式URLを優先してください: {item.get('sourceUrl')}")
        parse_date(item.get("updatedAt", ""), f"{item['id']}.updatedAt", errors)

    for normalized_name, ids in item_names.items():
        if len(set(ids)) > 1:
            errors.append(f"品目名が重複しています: {normalized_name} -> {', '.join(sorted(set(ids)))}")

    alias_duplicates = [
        (normalized_alias, sorted(set(ids)))
        for normalized_alias, ids in alias_index.items()
        if normalized_alias and len(set(ids)) > 1
    ]
    for normalized_alias, ids in alias_duplicates[:25]:
        warnings.append(f"aliasが複数品目に使われています: {normalized_alias} -> {', '.join(ids)}")
    if len(alias_duplicates) > 25:
        warnings.append(f"alias重複警告は先頭25件のみ表示しました。残り={len(alias_duplicates) - 25}件")

    item_category_ids = {item["categoryId"] for item in items}
    empty_categories = sorted(category_ids - item_category_ids)
    if empty_categories:
        errors.append(f"品目が1件もないカテゴリがあります: {', '.join(empty_categories)}")

    town_index: dict[str, list[tuple[str, str | None]]] = defaultdict(list)
    for area in areas:
        if area.get("sourceStatus") != "official-confirmed":
            warnings.append(f"{area['id']}: 公式確認済みではありません: {area.get('sourceStatus')}")
        for town in area["towns"]:
            if town["areaId"] != area["id"]:
                errors.append(f"{area['id']}/{town['townName']}: town.areaId が親地区と一致しません")
            if town["areaId"] not in area_ids:
                errors.append(f"{town['townName']}: 存在しない地区を参照しています: {town['areaId']}")
            town_index[normalize_text(town["townName"])].append((town["areaId"], town.get("blockRange")))

    if ("A", None) not in town_index.get(normalize_text("大倉町"), []):
        errors.append("大倉町 -> A地区 の町名ルールが見つかりません")

    for town_name, refs in town_index.items():
        if len(refs) > 1 and any(block is None for _, block in refs):
            errors.append(f"地区をまたぐ町名に番地範囲がありません: {town_name}")

    schedules_by_area: dict[str, set[str]] = defaultdict(set)
    for schedule in schedules:
        area_id = schedule["areaId"]
        category_id = schedule["categoryId"]
        schedules_by_area[area_id].add(category_id)
        if area_id not in area_ids:
            errors.append(f"{schedule['id']}: 存在しない地区を参照しています: {area_id}")
        if category_id not in category_ids:
            errors.append(f"{schedule['id']}: 存在しないカテゴリを参照しています: {category_id}")
        if schedule.get("sourceStatus") != "official-confirmed":
            warnings.append(f"{schedule['id']}: 公式確認済みではありません: {schedule.get('sourceStatus')}")

        valid_from = parse_date(schedule["validFrom"], f"{schedule['id']}.validFrom", errors)
        valid_to = parse_date(schedule["validTo"], f"{schedule['id']}.validTo", errors)
        if valid_from and valid_to and valid_from > valid_to:
            errors.append(f"{schedule['id']}: validFrom が validTo より後です")

        recurrence = schedule["recurrenceType"]
        if recurrence == "weekly" and not schedule.get("weekdays"):
            errors.append(f"{schedule['id']}: weekly には weekdays が必要です")
        if recurrence == "monthlyNthWeekday":
            if not schedule.get("weekdays") or not schedule.get("weekOfMonth"):
                errors.append(f"{schedule['id']}: monthlyNthWeekday には weekdays と weekOfMonth が必要です")
        if recurrence == "specificDates" and not schedule.get("specificDates"):
            errors.append(f"{schedule['id']}: specificDates には specificDates が必要です")

    for area_id in sorted(area_ids):
        missing = EXPECTED_SCHEDULE_CATEGORIES - schedules_by_area[area_id]
        if missing:
            errors.append(f"{area_id}地区: 必須収集カテゴリが不足しています: {', '.join(sorted(missing))}")

    for exception in special.get("exceptions", []):
        parse_date(exception["date"], f"exception.{exception.get('id', exception.get('date'))}", errors)
        if exception["areaId"] not in area_ids:
            errors.append(f"例外日が存在しない地区を参照しています: {exception['areaId']}")
        if exception["categoryId"] not in category_ids:
            errors.append(f"例外日が存在しないカテゴリを参照しています: {exception['categoryId']}")
        if exception.get("confidence") != "confirmed":
            errors.append(f"確定例外日は confidence=confirmed のみ登録できます: {exception}")
        if not str(exception.get("sourceUrl", "")).startswith("https://www.city.kadoma.osaka.jp/"):
            errors.append(f"例外日の sourceUrl は門真市公式URLが必要です: {exception}")
        parse_date(exception.get("confirmedAt", ""), f"exception.{exception.get('id', exception.get('date'))}.confirmedAt", errors)

    for rule in special.get("exceptionRules", []):
        date_from = parse_date(rule["dateFrom"], f"{rule['id']}.dateFrom", errors)
        date_to = parse_date(rule["dateTo"], f"{rule['id']}.dateTo", errors)
        parse_date(rule["confirmedAt"], f"{rule['id']}.confirmedAt", errors)
        if date_from and date_to and date_from > date_to:
            errors.append(f"{rule['id']}: dateFrom が dateTo より後です")
        for area_id in rule["areaIds"]:
            if area_id not in area_ids:
                errors.append(f"{rule['id']}: 存在しない地区を参照しています: {area_id}")
        for category_id in rule["affectedCategories"]:
            if category_id not in category_ids:
                errors.append(f"{rule['id']}: 存在しないカテゴリを参照しています: {category_id}")
        if rule["confidence"] not in CONFIDENCE_STATUSES:
            errors.append(f"{rule['id']}: confidence が不正です: {rule['confidence']}")
        if rule["confidence"] != "confirmed":
            warnings.append(f"{rule['id']}: 未確定の例外レビュー情報です。収集日を断定表示しないでください")
        if not str(rule.get("sourceUrl", "")).startswith("https://www.city.kadoma.osaka.jp/"):
            errors.append(f"{rule['id']}: sourceUrl は門真市公式URLが必要です")

    return errors, warnings


def validate_master_file(path: Path) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    if not path.exists():
        errors.append(f"{path} が見つかりません")
        return errors, warnings
    master = load_json(path)
    errors.extend(validate_against_schema(master, load_json(SCHEMA_FILES["master"]), f"master:{path.name}"))

    area_ids = {area["id"] for area in master.get("areas", [])}
    category_ids = {category["id"] for category in master.get("categories", [])}
    if area_ids != EXPECTED_AREA_IDS:
        errors.append(f"{path}: masterにA-F全地区が含まれていません: {sorted(area_ids)}")
    if master.get("defaultAreaId") not in area_ids:
        errors.append(f"{path}: defaultAreaId が master.areas に存在しません")
    for area in master.get("areas", []):
        for schedule in area.get("schedules", []):
            if schedule.get("categoryId") not in category_ids:
                errors.append(f"{path}: {area['id']}/{schedule.get('id')} が存在しないカテゴリを参照しています")

    return errors, warnings


def validate_manifest_sha() -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    if not DOCS_MASTER_PATH.exists() or not MANIFEST_PATH.exists():
        errors.append("docs master または manifest が見つかりません")
        return errors, warnings

    master_bytes = DOCS_MASTER_PATH.read_bytes()
    expected_sha = hashlib.sha256(master_bytes).hexdigest()
    manifest = load_json(MANIFEST_PATH)
    if manifest.get("sha256") != expected_sha:
        errors.append("manifest.sha256 が docs/kadoma_27223_2026_master.json と一致しません")
    if manifest.get("latestVersion") != load_json(DOCS_MASTER_PATH).get("version"):
        errors.append("manifest.latestVersion が master.version と一致しません")
    return errors, warnings


def load_split_data() -> dict[str, Any]:
    return {key: load_json(path) for key, path in SPLIT_FILES.items()}


def validate_all(split_only: bool = False) -> tuple[list[str], list[str]]:
    data = load_split_data()
    errors, warnings = validate_schema_files(data)
    relationship_errors, relationship_warnings = validate_relationships(data)
    errors.extend(relationship_errors)
    warnings.extend(relationship_warnings)

    if not split_only:
        for path in (RESOURCE_MASTER_PATH, DOCS_MASTER_PATH):
            master_errors, master_warnings = validate_master_file(path)
            errors.extend(master_errors)
            warnings.extend(master_warnings)
        sha_errors, sha_warnings = validate_manifest_sha()
        errors.extend(sha_errors)
        warnings.extend(sha_warnings)
    return errors, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Kadoma garbage split and master data.")
    parser.add_argument("--split-only", action="store_true", help="Validate split JSON only.")
    args = parser.parse_args()

    try:
        errors, warnings = validate_all(split_only=args.split_only)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    for warning in warnings:
        print(f"WARNING: {warning}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    scope = "split JSON" if args.split_only else "split JSON, master JSON, manifest"
    print(f"OK: {scope} validation passed ({len(warnings)} warnings)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
