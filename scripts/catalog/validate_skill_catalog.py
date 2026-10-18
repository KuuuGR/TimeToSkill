#!/usr/bin/env python3
"""Validate an approved Time4Skill skill catalog.

Reads JSONL or JSON. Does not modify the input. Exits 0 when there are no
blocking structural errors. Warnings and editorial suggestions do not fail
the run.

Emoji check is a presence and frequency report, not full Unicode emoji
segmentation. A repeated emoji is not an error.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from collections import Counter, defaultdict
from difflib import SequenceMatcher
from pathlib import Path


REQUIRED_STRINGS = ("skill_id", "name", "description", "category", "emoji", "emoji_rationale")
ALLOWED_REVIEW = ("unreviewed", "accepted", "rejected", "needs_source")
LEVEL_STRINGS = ("name", "completion_criterion", "can_do")

# Code points commonly used for emoji, plus joiners that belong inside one
# pictograph. This is not a complete Unicode emoji segmentation.
EMOJI_RANGES = (
    (0x203C, 0x203C),
    (0x2049, 0x2049),
    (0x2122, 0x2122),
    (0x2139, 0x2139),
    (0x2194, 0x2199),
    (0x21A9, 0x21AA),
    (0x231A, 0x231B),
    (0x2328, 0x2328),
    (0x23CF, 0x23CF),
    (0x23E9, 0x23F3),
    (0x23F8, 0x23FA),
    (0x24C2, 0x24C2),
    (0x25AA, 0x25AB),
    (0x25B6, 0x25B6),
    (0x25C0, 0x25C0),
    (0x25FB, 0x25FE),
    (0x2600, 0x27BF),
    (0x2934, 0x2935),
    (0x2B05, 0x2B07),
    (0x2B1B, 0x2B1C),
    (0x2B50, 0x2B50),
    (0x2B55, 0x2B55),
    (0x3030, 0x3030),
    (0x303D, 0x303D),
    (0x3297, 0x3299),
    (0xFE0F, 0xFE0F),
    (0x200D, 0x200D),
    (0x20E3, 0x20E3),
    (0x1F1E6, 0x1F1FF),
    (0x1F3FB, 0x1F3FF),
    (0x1F000, 0x1FAFF),
)
JOINER_OR_MODIFIER = {0x200D, 0xFE0E, 0xFE0F, 0x20E3} | set(range(0x1F3FB, 0x1F400))


def in_emoji_range(cp: int) -> bool:
    return any(start <= cp <= end for start, end in EMOJI_RANGES)


def repo_root_from_script() -> Path:
    return Path(__file__).resolve().parents[2]


def records_from_json_document(data, path: Path):
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        for key in ("records", "skills", "items", "approved_skills"):
            if isinstance(data.get(key), list):
                return data[key]
        if "skill_id" in data or "example" in data:
            return [data]
    raise ValueError(f"JSON object at {path} does not contain a record list")


def load_jsonl_lines(text: str, path: Path):
    records = []
    for line_no, line in enumerate(text.splitlines(), 1):
        if not line.strip():
            continue
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError as exc:
            raise ValueError(f"{path}:{line_no}: invalid JSON: {exc}") from exc
    return records


def load_json_or_jsonl(path: Path):
    text = path.read_text(encoding="utf-8")
    if not text.strip():
        return []
    try:
        return records_from_json_document(json.loads(text), path)
    except json.JSONDecodeError as exc:
        if "Extra data" not in str(exc):
            raise ValueError(f"{path}: invalid JSON: {exc}") from exc
        return load_jsonl_lines(text, path)


def load_allowed_review(repo: Path | None) -> tuple[set[str], str | None]:
    if repo is None:
        return set(ALLOWED_REVIEW), None
    schema_path = repo / "docs" / "catalog-research" / "approved-skill-schema.json"
    if not schema_path.is_file():
        return set(ALLOWED_REVIEW), f"schema not found at {schema_path}"
    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    allowed = schema.get("fields", {}).get("review_status", {}).get("allowed")
    if not isinstance(allowed, list) or not allowed:
        return set(ALLOWED_REVIEW), "schema review_status.allowed missing; using built-in list"
    return set(allowed), None


def load_known_ids(repo: Path | None) -> tuple[set[str] | None, set[str] | None, list[str]]:
    notes = []
    if repo is None:
        return None, None, ["no repository path; source links were not resolved"]
    raw_path = repo / "data" / "skills-catalog" / "research" / "candidates-raw.jsonl"
    sources_path = repo / "data" / "skills-catalog" / "research" / "sources.json"
    candidates = None
    sources = None
    if raw_path.is_file():
        candidates = set()
        with raw_path.open(encoding="utf-8") as handle:
            for line_no, line in enumerate(handle, 1):
                if not line.strip():
                    continue
                try:
                    row = json.loads(line)
                except json.JSONDecodeError:
                    notes.append(f"candidates-raw.jsonl line {line_no} is not valid JSON")
                    continue
                cid = row.get("candidate_id")
                if isinstance(cid, str) and cid:
                    candidates.add(cid)
    else:
        notes.append("candidates-raw.jsonl not found; candidate links were not resolved")
    if sources_path.is_file():
        sources = set()
        data = json.loads(sources_path.read_text(encoding="utf-8"))
        rows = data.get("sources", []) if isinstance(data, dict) else data
        if isinstance(rows, list):
            for row in rows:
                if isinstance(row, dict) and isinstance(row.get("source_id"), str):
                    sources.add(row["source_id"])
        else:
            notes.append("sources.json has no source list")
            sources = None
    else:
        notes.append("sources.json not found; source links were not resolved")
    return candidates, sources, notes


def norm_name(value: str) -> str:
    text = unicodedata.normalize("NFKC", value).casefold()
    return re.sub(r"\s+", " ", text).strip()


def looks_observable(text: str) -> bool:
    words = re.findall(r"[^\W\d_]+", text, flags=re.UNICODE)
    return len(text.strip()) >= 24 and len(words) >= 4


def emoji_parts(value: str) -> tuple[list[str], list[str]]:
    """Return (pictograph clusters approximated, leftover characters).

    A cluster is a run of emoji-range code points. Joiners and variation
    selectors stay inside the run. This can split a ZWJ sequence if a joiner
    is missing, and it can accept a symbol that is not an emoji in the latest
    Unicode charts. It does not implement UAX #29 grapheme segmentation.
    """
    clusters = []
    leftover = []
    current = []
    for ch in value:
        cp = ord(ch)
        if in_emoji_range(cp) or (current and cp in JOINER_OR_MODIFIER):
            current.append(ch)
        else:
            if current:
                clusters.append("".join(current))
                current = []
            if not ch.isspace():
                leftover.append(ch)
    if current:
        clusters.append("".join(current))
    return clusters, leftover


class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []
        self.suggestions: list[str] = []

    def error(self, message: str) -> None:
        self.errors.append(message)

    def warning(self, message: str) -> None:
        self.warnings.append(message)

    def suggestion(self, message: str) -> None:
        self.suggestions.append(message)


def require_string(record: dict, field: str, where: str, report: Report) -> str | None:
    value = record.get(field, None)
    if not isinstance(value, str) or not value.strip():
        report.error(f"{where} field '{field}' must be a non-empty string")
        return None
    return value


def validate_record(
    record,
    index: int,
    report: Report,
    allowed_review: set[str],
    known_candidates: set[str] | None,
    known_sources: set[str] | None,
    seen_ids: dict[str, int],
    name_index: dict[str, list[str]],
    candidate_owners: dict[str, list[str]],
    emoji_owners: dict[str, list[str]],
    categories: Counter,
) -> None:
    where = f"record {index}"
    if not isinstance(record, dict):
        report.error(f"{where} is not an object")
        return
    skill_id = record.get("skill_id")
    if isinstance(skill_id, str) and skill_id.strip():
        where = f"{skill_id}"
        if skill_id in seen_ids:
            report.error(f"{where} duplicates skill_id first seen at record {seen_ids[skill_id]}")
        else:
            seen_ids[skill_id] = index
    else:
        report.error(f"{where} field 'skill_id' must be a non-empty string")
        skill_id = None

    name = require_string(record, "name", where, report)
    require_string(record, "description", where, report)
    category = require_string(record, "category", where, report)
    emoji = require_string(record, "emoji", where, report)
    require_string(record, "emoji_rationale", where, report)
    if category:
        categories[category] += 1
    if name and skill_id:
        name_index[norm_name(name)].append(skill_id)

    levels = record.get("levels")
    if not isinstance(levels, list) or len(levels) != 3:
        report.error(f"{where} field 'levels' must contain exactly 3 objects")
    else:
        for level_no, level in enumerate(levels, 1):
            level_where = f"{where} level {level_no}"
            if not isinstance(level, dict):
                report.error(f"{level_where} is not an object")
                continue
            for field in LEVEL_STRINGS:
                value = level.get(field)
                if not isinstance(value, str) or not value.strip():
                    report.error(f"{level_where} field '{field}' must be a non-empty string")
                elif field == "completion_criterion" and not looks_observable(value):
                    report.suggestion(
                        f"{level_where} completion_criterion is short or not clearly an observable action"
                    )
            if "safety_requirements" in level and level["safety_requirements"] is not None:
                if not isinstance(level["safety_requirements"], str):
                    report.error(f"{level_where} safety_requirements must be a string or null")
                elif not level["safety_requirements"].strip():
                    report.warning(f"{level_where} safety_requirements is an empty string")

    for field in ("source_candidate_ids", "source_ids", "tags"):
        values = record.get(field)
        if not isinstance(values, list):
            report.error(f"{where} field '{field}' must be an array of strings")
            continue
        for item in values:
            if not isinstance(item, str) or not item.strip():
                report.error(f"{where} field '{field}' contains an empty or non-string value")
        if field == "source_candidate_ids" and skill_id:
            if not values:
                report.warning(f"{where} has no source_candidate_ids")
            for item in values:
                if not isinstance(item, str) or not item.strip():
                    continue
                candidate_owners[item].append(skill_id)
                if known_candidates is not None and item not in known_candidates:
                    report.error(f"{where} source_candidate_id '{item}' is not in candidates-raw.jsonl")
        if field == "source_ids":
            if not values:
                report.warning(f"{where} has no source_ids")
            if known_sources is not None:
                for item in values:
                    if isinstance(item, str) and item.strip() and item not in known_sources:
                        report.error(f"{where} source_id '{item}' is not in sources.json")

    status = record.get("review_status")
    if not isinstance(status, str) or status not in allowed_review:
        report.error(
            f"{where} review_status must be one of: {', '.join(sorted(allowed_review))}"
        )
    if "safety_notes" in record and record["safety_notes"] is not None:
        if not isinstance(record["safety_notes"], str):
            report.error(f"{where} safety_notes must be a string or null")
        elif not record["safety_notes"].strip():
            report.warning(f"{where} safety_notes is an empty string")

    if emoji and skill_id:
        clusters, leftover = emoji_parts(emoji.strip())
        if leftover or not clusters:
            report.error(
                f"{where} emoji '{emoji}' is missing or cannot be read as an emoji symbol"
            )
        elif len(clusters) != 1:
            report.warning(
                f"{where} emoji field has {len(clusters)} symbol runs; guidelines ask for one emoji"
            )
            emoji_owners[emoji.strip()].append(skill_id)
        else:
            emoji_owners[clusters[0]].append(skill_id)


def add_diversity(
    report: Report,
    name_index: dict[str, list[str]],
    candidate_owners: dict[str, list[str]],
    categories: Counter,
    record_count: int,
) -> None:
    for key, ids in name_index.items():
        if len(ids) > 1:
            report.warning(
                "identical normalized name "
                f"'{key}' on skill_ids: {', '.join(ids)}. This is a review queue, not a merge."
            )
    names = [(key, ids[0]) for key, ids in name_index.items() if len(ids) == 1]
    for i, (left, left_id) in enumerate(names):
        left_tokens = set(left.split())
        for right, right_id in names[i + 1 :]:
            ratio = SequenceMatcher(None, left, right).ratio()
            right_tokens = set(right.split())
            union = left_tokens | right_tokens
            jaccard = (len(left_tokens & right_tokens) / len(union)) if union else 0
            if ratio >= 0.86 or (jaccard >= 0.8 and len(left_tokens & right_tokens) >= 2):
                report.suggestion(
                    "similar names for human review, not a semantic duplicate: "
                    f"{left_id} '{left}' and {right_id} '{right}' "
                    f"(text ratio {ratio:.2f}, token overlap {jaccard:.2f})"
                )
    for candidate_id, owners in candidate_owners.items():
        unique = list(dict.fromkeys(owners))
        if len(unique) > 1:
            report.warning(
                f"candidate_id '{candidate_id}' is linked from multiple skills: {', '.join(unique)}"
            )
    if record_count >= 10 and categories:
        top_category, top_count = categories.most_common(1)[0]
        share = top_count / record_count
        if share > 0.5:
            report.warning(
                f"category '{top_category}' holds {top_count}/{record_count} records ({share:.0%})"
            )


def emoji_section(emoji_owners: dict[str, list[str]], record_count: int) -> list[str]:
    lines = []
    uses = sum(len(ids) for ids in emoji_owners.values())
    lines.append(f"skills with a readable emoji: {uses} of {record_count}")
    lines.append(f"distinct emoji: {len(emoji_owners)}")
    if not emoji_owners:
        return lines
    ranked = sorted(emoji_owners.items(), key=lambda item: (-len(item[1]), item[0]))
    top = ranked[:5]
    top_uses = sum(len(ids) for _, ids in top)
    percent = (100.0 * top_uses / uses) if uses else 0
    lines.append(f"top 5 emoji account for {top_uses}/{uses} uses ({percent:.1f}%)")
    lines.append("frequency:")
    for symbol, ids in ranked:
        lines.append(f"  {symbol}  {len(ids)}")
    unusual = [
        (symbol, ids)
        for symbol, ids in ranked
        if len(ids) >= 8 or (record_count >= 30 and len(ids) / record_count > 0.1)
    ]
    if unusual:
        lines.append("unusually frequent emoji (review queue, not an error):")
        for symbol, ids in unusual:
            lines.append(f"  {symbol} skill_ids: {', '.join(ids)}")
    else:
        lines.append("no emoji crosses the frequency review threshold")
    lines.append(
        "method limit: emoji runs are detected from a fixed code-point list, "
        "not full Unicode grapheme or emoji-sequence segmentation"
    )
    return lines


def render(report: Report, emoji_lines: list[str], notes: list[str], summary: bool) -> str:
    lines = [
        f"errors: {len(report.errors)}",
        f"warnings: {len(report.warnings)}",
        f"suggestions: {len(report.suggestions)}",
    ]
    if notes:
        lines.append("notes:")
        lines.extend(f"  {note}" for note in notes)
    if summary:
        lines.append("emoji:")
        lines.extend(f"  {line}" for line in emoji_lines[:4])
        return "\n".join(lines) + "\n"
    for title, items in (
        ("errors", report.errors),
        ("warnings", report.warnings),
        ("suggestions", report.suggestions),
    ):
        lines.append(f"{title}:")
        if items:
            lines.extend(f"  - {item}" for item in items)
        else:
            lines.append("  - none")
    lines.append("emoji:")
    lines.extend(f"  {line}" for line in emoji_lines)
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate an approved skill catalog.")
    parser.add_argument("data", type=Path, help="JSON or JSONL file of approved skills")
    parser.add_argument(
        "--repo",
        type=Path,
        default=None,
        help="Repository root used to find the schema and source database. "
        "Defaults to the repository that contains this script.",
    )
    parser.add_argument("--summary", action="store_true", help="Print counts and the emoji headline only")
    args = parser.parse_args(argv)

    repo = args.repo.resolve() if args.repo else repo_root_from_script()
    if not repo.is_dir():
        print(f"error: repository path does not exist: {repo}", file=sys.stderr)
        return 2
    data_path = args.data
    if not data_path.is_file():
        print(f"error: data file does not exist: {data_path}", file=sys.stderr)
        return 2

    report = Report()
    try:
        records = load_json_or_jsonl(data_path)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    allowed_review, schema_note = load_allowed_review(repo)
    known_candidates, known_sources, notes = load_known_ids(repo)
    if schema_note:
        notes.append(schema_note)
    notes.insert(0, f"records read: {len(records)}")
    notes.insert(1, f"data: {data_path}")

    seen_ids: dict[str, int] = {}
    name_index: dict[str, list[str]] = defaultdict(list)
    candidate_owners: dict[str, list[str]] = defaultdict(list)
    emoji_owners: dict[str, list[str]] = defaultdict(list)
    categories: Counter = Counter()

    for index, record in enumerate(records, 1):
        validate_record(
            record,
            index,
            report,
            allowed_review,
            known_candidates,
            known_sources,
            seen_ids,
            name_index,
            candidate_owners,
            emoji_owners,
            categories,
        )
    add_diversity(report, name_index, candidate_owners, categories, len(records))
    emoji_lines = emoji_section(emoji_owners, len(records))
    sys.stdout.write(render(report, emoji_lines, notes, args.summary))
    return 1 if report.errors else 0


if __name__ == "__main__":
    sys.exit(main())
