#!/usr/bin/env python3
import argparse
import hashlib
import json
import re
import sys
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

SOURCES = [
    {
        "id": "district-calendar",
        "title": "地区別ごみカレンダー",
        "url": "https://www.city.kadoma.osaka.jp/kurashi/gomi/9/35805.html",
    },
    {
        "id": "sorting-guide",
        "title": "ごみの出し方・分け方",
        "url": "https://www.city.kadoma.osaka.jp/kurashi/gomi/9/6/4394.html",
    },
    {
        "id": "bulky-phone",
        "title": "粗大ごみの電話申込み",
        "url": "https://www.city.kadoma.osaka.jp/kurashi/gomi/9/5/22406.html",
    },
    {
        "id": "bulky-web",
        "title": "粗大ごみのインターネット申込み",
        "url": "https://www.city.kadoma.osaka.jp/kurashi/gomi/9/5/22408.html",
    },
]


def fetch(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": "kadoma-gomi-monitor/1.0"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read()


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def updated_at(html: str) -> str | None:
    match = re.search(r"更新日：([0-9]{4}年[0-9]{2}月[0-9]{2}日)", html)
    return match.group(1) if match else None


def pdf_links(base_url: str, html: str) -> list[str]:
    links = re.findall(r'href="([^"]+\.pdf[^"]*)"', html, flags=re.IGNORECASE)
    return sorted({urllib.parse.urljoin(base_url, link) for link in links})


def build_report() -> dict:
    checked = []
    for source in SOURCES:
        body = fetch(source["url"])
        html = body.decode("utf-8", errors="ignore")
        entry = {
            **source,
            "sha256": sha256(body),
            "updatedAtText": updated_at(html),
            "pdfs": [],
        }
        for pdf_url in pdf_links(source["url"], html):
            pdf_body = fetch(pdf_url)
            entry["pdfs"].append({"url": pdf_url, "sha256": sha256(pdf_body), "bytes": len(pdf_body)})
        checked.append(entry)
    return {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "sources": checked,
    }


def load_json(path: Path) -> dict | None:
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def diff_report(report: dict, baseline: dict | None) -> list[dict]:
    if baseline is None:
        return []
    baseline_sources = {source["id"]: source for source in baseline.get("sources", [])}
    changes = []
    for source in report["sources"]:
        old = baseline_sources.get(source["id"])
        if old is None:
            changes.append({"id": source["id"], "type": "new-source"})
            continue
        if old.get("sha256") != source.get("sha256"):
            changes.append({"id": source["id"], "type": "html-sha256"})
        old_pdfs = {pdf["url"]: pdf for pdf in old.get("pdfs", [])}
        for pdf in source.get("pdfs", []):
            if old_pdfs.get(pdf["url"], {}).get("sha256") != pdf.get("sha256"):
                changes.append({"id": source["id"], "type": "pdf-sha256", "url": pdf["url"]})
    return changes


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", default="docs/source_hashes.json")
    parser.add_argument("--output", default="build/source-report.json")
    args = parser.parse_args()

    report = build_report()
    baseline = load_json(Path(args.baseline))
    changes = diff_report(report, baseline)
    report["changes"] = changes
    report["changed"] = bool(changes)

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(json.dumps({"changed": bool(changes), "changes": changes}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())

