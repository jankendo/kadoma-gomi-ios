#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
import unicodedata
from collections import defaultdict
from datetime import date, timedelta
from pathlib import Path

from generate_master import build_master, default_generated_at
from validate_data import EXPECTED_AREA_IDS, ROOT, load_split_data, normalize_text


EXPECTED_CALENDAR_CASES = {
    ("A", "2026-05-25"): {"plastic_container"},
    ("A", "2026-05-26"): {"burnable"},
    ("B", "2026-05-25"): {"bottles_cans", "bulky"},
    ("C", "2026-05-25"): {"burnable"},
    ("D", "2026-05-26"): {"bottles_cans", "bulky"},
    ("E", "2026-05-26"): {"burnable", "plastic_container"},
    ("F", "2026-05-26"): {"burnable", "bottles_cans", "bulky"},
}

EXPECTED_SEARCH_CASES = {
    "ペットボトル": "pet_bottle",
    "ぺっとぼとる": "pet_bottle",
    "PET": "pet_bottle",
    "ダンボール": "paper_cloth",
    "段ボール": "paper_cloth",
    "缶": "bottles_cans",
    "カン": "bottles_cans",
    "びん": "bottles_cans",
    "ビン": "bottles_cans",
    "プラ": "plastic_container",
    "リチウム": "hazardous_note",
    "リチュウム電池": "hazardous_note",
    "モバイルバッテリー": "hazardous_note",
    "金属ハンガー": "small_items",
    "衣類乾燥機": "recycle_law",
    "ベビーカー": "bulky",
    "Tシャツ": "paper_cloth",
    "ヘアスプレー": "bottles_cans",
}


def run_command(args: list[str]) -> None:
    print("+ " + " ".join(args))
    subprocess.run(args, cwd=ROOT, check=True)


def weekday_number(day: date) -> int:
    return day.weekday() + 1


def week_of_month(day: date) -> int:
    return ((day.day - 1) // 7) + 1


def parse_day(value: str) -> date:
    return date.fromisoformat(value)


def date_matches(schedule: dict, day: date) -> bool:
    if not (parse_day(schedule["validFrom"]) <= day <= parse_day(schedule["validTo"])):
        return False
    recurrence = schedule["recurrenceType"]
    if recurrence == "weekly":
        return weekday_number(day) in (schedule.get("weekdays") or [])
    if recurrence == "monthlyNthWeekday":
        return (
            weekday_number(day) in (schedule.get("weekdays") or [])
            and week_of_month(day) in (schedule.get("weekOfMonth") or [])
        )
    if recurrence == "specificDates":
        return day.isoformat() in (schedule.get("specificDates") or [])
    return False


def events_for(master: dict, area_id: str, day: date) -> set[str]:
    area = next(area for area in master["areas"] if area["id"] == area_id)
    categories = {schedule["categoryId"] for schedule in area["schedules"] if date_matches(schedule, day)}
    for exception in area.get("exceptions", []):
        if exception["date"] != day.isoformat():
            continue
        if exception["action"] == "cancel":
            categories.discard(exception["categoryId"])
        if exception["action"] == "add":
            categories.add(exception["categoryId"])
    return categories


def run_calendar_tests(master: dict) -> None:
    for area_id in EXPECTED_AREA_IDS:
        events = []
        current = date(2026, 4, 1)
        while current <= date(2027, 3, 31):
            if events_for(master, area_id, current):
                events.append(current)
            current += timedelta(days=1)
        if not events:
            raise AssertionError(f"{area_id}地区の収集日が1件も生成されません")

    for (area_id, day_text), expected in EXPECTED_CALENDAR_CASES.items():
        actual = events_for(master, area_id, parse_day(day_text))
        if actual != expected:
            raise AssertionError(f"{area_id} {day_text}: expected={expected}, actual={actual}")
    print("OK: calendar smoke tests passed")


def search_variants(text: str) -> set[str]:
    normalized = normalize_text(text)
    variants = {normalized}
    aliases = {
        "pet": ["ペット", "ペットボトル"],
        "ペット": ["pet", "ペットボトル"],
        "ボトル": ["ペットボトル", "プラスチックボトル"],
        "プラ": ["プラスチック", "プラスチック製容器包装"],
        "ダンボール": ["段ボール"],
        "段ボール": ["ダンボール"],
        "カン": ["缶"],
        "缶": ["カン"],
        "ビン": ["びん", "瓶"],
        "びん": ["ビン", "瓶"],
        "リチウム": ["リチウムイオン電池", "リチュウム", "リチューム"],
        "リチュウム": ["リチウム", "リチウムイオン電池"],
        "モバイル": ["モバイルバッテリー", "バッテリー"],
        "バッテリー": ["モバイルバッテリー", "充電式電池", "リチウムイオン電池"],
        "スプレー": ["スプレー缶", "ヘアスプレー缶", "塗料スプレー缶"],
        "ボンベ": ["カセットボンベ", "簡易ガスボンベ", "卓上コンロ用ボンベ"],
        "古着": ["衣類", "Tシャツ", "セーター", "ジーンズ"],
        "本": ["雑誌", "教科書", "書籍"],
        "粗大": ["粗大ごみ", "大型", "30cm超"],
        "大型": ["粗大ごみ", "30cm超"],
    }
    for key, values in aliases.items():
        if normalize_text(key) == normalized:
            variants.update(normalize_text(value) for value in values)
    return variants


def search_score(item: dict, category: dict, query: str) -> int:
    variants = search_variants(query)
    score = 0
    targets = [(item.get("displayName", item["names"][0]), 120, 70, 35)]
    targets += [(name, 100, 60, 30) for name in item["names"]]
    targets += [(keyword, 40, 24, 10) for keyword in set(item.get("aliases", []) + item["keywords"] + [item.get("kana", "")])]
    targets += [(category["name"], 70, 45, 18), (category["shortName"], 80, 40, 18)]
    targets += [(item.get("disposalGuide", item["notes"]), 0, 10, 0)]
    targets += [(warning, 0, 8, 0) for warning in item.get("warnings", [])]
    for text, exact, contains, reverse in targets:
        normalized = normalize_text(text)
        for variant in variants:
            if normalized == variant:
                score += exact
            elif normalized in variant:
                score += reverse
            elif variant in normalized:
                score += contains
    if query in {normalize_text("プラ"), normalize_text("プラスチック")}:
        if item["categoryId"] == "plastic_container":
            score += 140
        if item["categoryId"] == "burnable":
            score -= 35
    if normalize_text("リチウム") in query or normalize_text("リチュウム") in query or "liion" in query:
        if item["categoryId"] == "hazardous_note":
            score += 180
        if item.get("displayName") == "電池":
            score -= 60
    if normalize_text(item["notes"]) in variants:
        score += 8
    return score


def run_search_tests(master: dict) -> None:
    categories = {category["id"]: category for category in master["categories"]}
    for query, expected_category in EXPECTED_SEARCH_CASES.items():
        ranked = sorted(
            master["itemDictionary"],
            key=lambda item: (search_score(item, categories[item["categoryId"]], query), item["id"]),
            reverse=True,
        )
        top = next((item for item in ranked if search_score(item, categories[item["categoryId"]], query) > 0), None)
        if top is None:
            raise AssertionError(f"検索結果なし: {query}")
        if top["categoryId"] != expected_category:
            raise AssertionError(f"{query}: expected={expected_category}, actual={top['categoryId']} ({top['names'][0]})")
    print("OK: search smoke tests passed")


def run_data_quality_tests(master: dict) -> None:
    item_count = len(master["itemDictionary"])
    if item_count < 200:
        raise AssertionError(f"検索辞書が200品目未満です: {item_count}")
    if master.get("municipalityName") != "門真市" or master.get("municipalityCode") != "27223":
        raise AssertionError("門真市限定マスタではありません")
    if {area["id"] for area in master["areas"]} != EXPECTED_AREA_IDS:
        raise AssertionError("A-F全地区が維持されていません")
    if not any(item.get("requiresOfficialCheck") for item in master["itemDictionary"]):
        raise AssertionError("公式確認推奨品目が表現できていません")
    for category in master["categories"]:
        if len(category.get("disposalSteps", [])) < 3:
            raise AssertionError(f"{category['id']}: カテゴリ別の出し方ステップが不足しています")
        if not category.get("examples"):
            raise AssertionError(f"{category['id']}: 代表品目 examples が不足しています")
    for item in master["itemDictionary"]:
        if len(item.get("disposalSteps", [])) < 2:
            raise AssertionError(f"{item['id']}: 品目別 disposalSteps が不足しています")
        if not item.get("sourceTitle"):
            raise AssertionError(f"{item['id']}: sourceTitle が不足しています")
    if not master.get("exceptionRules"):
        raise AssertionError("年末年始レビュー用 exceptionRules がありません")
    for rule in master["exceptionRules"]:
        if rule.get("confidence") != "needs_review":
            raise AssertionError("未確定の年末年始ルールは needs_review として扱ってください")
    print("OK: phase3 data quality tests passed")


def run_notification_preview_tests(master: dict) -> None:
    categories = master["categories"]
    settings = {
        "previousNightNotificationEnabled": True,
        "morningNotificationEnabled": True,
        "previousNightHour": 20,
        "morningHour": 7,
        "morningMinute": 30,
    }
    tomorrow_events = events_for(master, "A", date(2026, 5, 26))
    if "burnable" not in tomorrow_events:
        raise AssertionError("通知プレビュー対象の普通ごみ日が生成できません")
    burnable = next(category for category in categories if category["id"] == "burnable")
    if not burnable["defaultPreviousNightNotification"] or not burnable["defaultMorningNotification"]:
        raise AssertionError("普通ごみの前日/当日通知デフォルトが崩れています")
    bulky = next(category for category in categories if category["id"] == "bulky")
    if bulky["defaultPreviousNightNotification"] or bulky["defaultMorningNotification"]:
        raise AssertionError("粗大ごみは通常通知対象にしない設計です")
    if not settings["previousNightNotificationEnabled"] or not settings["morningNotificationEnabled"]:
        raise AssertionError("通知設定の検証前提が不正です")
    print("OK: notification preview smoke tests passed")


def main() -> int:
    try:
        run_command([sys.executable, "Scripts/validate_data.py", "--split-only"])
        run_command([sys.executable, "Scripts/generate_master.py", "--check"])
        run_command([sys.executable, "Scripts/validate_data.py"])
        master = build_master(default_generated_at())
        run_data_quality_tests(master)
        run_calendar_tests(master)
        run_search_tests(master)
        run_notification_preview_tests(master)
    except subprocess.CalledProcessError as exc:
        return exc.returncode
    except AssertionError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
