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
    }
    for key, values in aliases.items():
        if normalize_text(key) == normalized:
            variants.update(normalize_text(value) for value in values)
    return variants


def search_score(item: dict, category: dict, query: str) -> int:
    variants = search_variants(query)
    score = 0
    targets = [(name, 100, 60, 30) for name in item["names"]]
    targets += [(keyword, 40, 24, 10) for keyword in item["keywords"]]
    targets += [(category["name"], 70, 45, 18), (category["shortName"], 80, 40, 18)]
    for text, exact, contains, reverse in targets:
        normalized = normalize_text(text)
        for variant in variants:
            if normalized == variant:
                score += exact
            elif normalized in variant:
                score += reverse
            elif variant in normalized:
                score += contains
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


def main() -> int:
    try:
        run_command([sys.executable, "Scripts/validate_data.py", "--split-only"])
        run_command([sys.executable, "Scripts/generate_master.py", "--check"])
        run_command([sys.executable, "Scripts/validate_data.py"])
        master = build_master(default_generated_at())
        run_calendar_tests(master)
        run_search_tests(master)
    except subprocess.CalledProcessError as exc:
        return exc.returncode
    except AssertionError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
