#!/usr/bin/env python3
from __future__ import annotations

import argparse
import difflib
import hashlib
import json
import os
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any

from validate_data import (
    DOCS_MASTER_PATH,
    MANIFEST_PATH,
    RESOURCE_MASTER_PATH,
    ROOT,
    dump_json,
    load_json,
    load_split_data,
    validate_all,
)


MASTER_VERSION = "2026.04.01-af.4"
SOURCE_UPDATED_AT = "2026-03-30"
MASTER_FILE_NAME = "kadoma_27223_2026_master.json"
DIFF_PATH = ROOT / "build" / "master_diff.txt"

SOURCE_PAGES = [
    {
        "title": "地区別ごみカレンダー",
        "url": "https://www.city.kadoma.osaka.jp/kurashi/gomi/9/35805.html",
        "updatedAt": SOURCE_UPDATED_AT,
    },
    {
        "title": "ごみの出し方・分け方",
        "url": "https://www.city.kadoma.osaka.jp/kurashi/gomi/9/6/4394.html",
        "updatedAt": SOURCE_UPDATED_AT,
    },
    {
        "title": "ごみの出し方・分け方 共通PDF",
        "url": "https://www.city.kadoma.osaka.jp/material/files/group/20/kyoutuu.pdf",
        "updatedAt": SOURCE_UPDATED_AT,
    },
    {
        "title": "粗大ごみの電話申込み",
        "url": "https://www.city.kadoma.osaka.jp/kurashi/gomi/9/5/22406.html",
        "updatedAt": "2025-11-04",
    },
    {
        "title": "粗大ごみのインターネット申込み",
        "url": "https://www.city.kadoma.osaka.jp/kurashi/gomi/9/5/22408.html",
        "updatedAt": "2023-04-03",
    },
]


def default_generated_at() -> str:
    env_value = os.environ.get("KADOMA_GENERATED_AT")
    if env_value:
        return env_value
    if DOCS_MASTER_PATH.exists():
        existing = load_json(DOCS_MASTER_PATH)
        if existing.get("version") == MASTER_VERSION and existing.get("generatedAt"):
            return existing["generatedAt"]
    if RESOURCE_MASTER_PATH.exists():
        existing = load_json(RESOURCE_MASTER_PATH)
        if existing.get("version") == MASTER_VERSION and existing.get("generatedAt"):
            return existing["generatedAt"]
    jst = timezone(timedelta(hours=9))
    return datetime.now(jst).replace(microsecond=0).isoformat()


def sanitize_schedule(schedule: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": schedule["id"],
        "categoryId": schedule["categoryId"],
        "recurrenceType": schedule["recurrenceType"],
        "weekdays": schedule.get("weekdays"),
        "weekOfMonth": schedule.get("weekOfMonth"),
        "specificDates": schedule.get("specificDates"),
        "validFrom": schedule["validFrom"],
        "validTo": schedule["validTo"],
    }


def sanitize_area(area: dict[str, Any], schedules: list[dict[str, Any]], exceptions: list[dict[str, Any]]) -> dict[str, Any]:
    area_schedules = [sanitize_schedule(schedule) for schedule in schedules if schedule["areaId"] == area["id"]]
    area_exceptions = [
        {
            "date": exception["date"],
            "areaId": exception["areaId"],
            "categoryId": exception["categoryId"],
            "action": exception["action"],
            "reason": exception["reason"],
        }
        for exception in exceptions
        if exception["areaId"] == area["id"]
    ]
    return {
        "id": area["id"],
        "name": area["name"],
        "towns": area["towns"],
        "schedules": area_schedules,
        "exceptions": area_exceptions,
    }


def build_master(generated_at: str) -> dict[str, Any]:
    data = load_split_data()
    areas = [
        sanitize_area(area, data["schedules"], data["special"].get("exceptions", []))
        for area in sorted(data["areas"], key=lambda item: item["id"])
    ]
    return {
        "municipalityCode": "27223",
        "municipalityName": "門真市",
        "targetAddressPreset": "大倉町1-20",
        "defaultAreaId": "A",
        "fiscalYear": 2026,
        "version": MASTER_VERSION,
        "sourceUpdatedAt": SOURCE_UPDATED_AT,
        "generatedAt": generated_at,
        "sourcePages": SOURCE_PAGES,
        "areas": areas,
        "categories": data["categories"],
        "itemDictionary": data["items"],
        "notices": data["special"].get("notices", []),
        "exceptionRules": data["special"].get("exceptionRules", []),
    }


def build_manifest(master: dict[str, Any], master_text: str) -> dict[str, Any]:
    return {
        "municipalityCode": master["municipalityCode"],
        "latestVersion": master["version"],
        "fiscalYear": master["fiscalYear"],
        "masterUrl": MASTER_FILE_NAME,
        "sha256": hashlib.sha256(master_text.encode("utf-8")).hexdigest(),
        "sourceUpdatedAt": master["sourceUpdatedAt"],
        "generatedAt": master["generatedAt"],
        "requiresReview": True,
        "message": "A-F地区の2026年度基本曜日と検索辞書拡張を反映しました。年末年始は公式情報も確認してください。",
    }


def diff_text(path: Path, new_text: str) -> str:
    old_text = path.read_text(encoding="utf-8") if path.exists() else ""
    if old_text == new_text:
        return ""
    return "".join(
        difflib.unified_diff(
            old_text.splitlines(keepends=True),
            new_text.splitlines(keepends=True),
            fromfile=str(path),
            tofile=f"{path} (generated)",
        )
    )


def write_diff_report(diffs: list[str], master: dict[str, Any], manifest: dict[str, Any]) -> None:
    DIFF_PATH.parent.mkdir(parents=True, exist_ok=True)
    summary = [
        "Kadoma master generation diff",
        f"version: {master['version']}",
        f"areas: {len(master['areas'])}",
        f"schedules: {sum(len(area['schedules']) for area in master['areas'])}",
        f"items: {len(master['itemDictionary'])}",
        f"sha256: {manifest['sha256']}",
        "",
    ]
    DIFF_PATH.write_text("\n".join(summary) + "\n".join(diffs), encoding="utf-8", newline="\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate production master JSON and manifest from split data.")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true", help="Write generated files.")
    mode.add_argument("--check", action="store_true", help="Fail if generated files differ from committed files.")
    parser.add_argument("--generated-at", default=None, help="ISO-8601 generatedAt value. Defaults to existing value or now.")
    args = parser.parse_args()

    errors, warnings = validate_all(split_only=True)
    for warning in warnings:
        print(f"WARNING: {warning}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    generated_at = args.generated_at or default_generated_at()
    master = build_master(generated_at)
    master_text = dump_json(master)
    manifest = build_manifest(master, master_text)
    manifest_text = dump_json(manifest)

    diffs = [
        diff_text(RESOURCE_MASTER_PATH, master_text),
        diff_text(DOCS_MASTER_PATH, master_text),
        diff_text(MANIFEST_PATH, manifest_text),
    ]
    diffs = [diff for diff in diffs if diff]
    write_diff_report(diffs, master, manifest)

    if args.check:
        if diffs:
            print(f"ERROR: generated files differ. See {DIFF_PATH}", file=sys.stderr)
            return 1
        print("OK: generated master and manifest are up to date")
        return 0

    RESOURCE_MASTER_PATH.write_text(master_text, encoding="utf-8", newline="\n")
    DOCS_MASTER_PATH.write_text(master_text, encoding="utf-8", newline="\n")
    MANIFEST_PATH.write_text(manifest_text, encoding="utf-8", newline="\n")
    print(f"OK: wrote {RESOURCE_MASTER_PATH}")
    print(f"OK: wrote {DOCS_MASTER_PATH}")
    print(f"OK: wrote {MANIFEST_PATH}")
    print(f"OK: diff report {DIFF_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
