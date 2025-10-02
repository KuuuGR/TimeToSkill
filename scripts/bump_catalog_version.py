#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path


def parse_version_tuple(v: str) -> tuple[int, int, int]:
    parts = v.strip().split(".")
    nums = [int(p) for p in parts if p.isdigit()]
    while len(nums) < 3:
        nums.append(0)
    return tuple(nums[:3])


def is_version_increase(old: str, new: str) -> bool:
    if not old:
        return True
    o = parse_version_tuple(old)
    n = parse_version_tuple(new)
    return n > o


def main() -> int:
    project_dir_env = os.environ.get("PROJECT_DIR")
    # Fallback when running manually (repo root)
    repo_root = Path(__file__).resolve().parents[1]

    # Probe possible locations of the Resources folder to support both CLI and Xcode runs
    candidate_roots = []
    if project_dir_env:
        p = Path(project_dir_env)
        candidate_roots += [
            p / "TimeToSkill" / "Resources",               # PROJECT_DIR points at repo subdir (common in Xcode)
            p / "TimeToSkill" / "TimeToSkill" / "Resources",  # Safety for different nesting
        ]
    # Manual runs from repo root
    candidate_roots += [
        repo_root / "TimeToSkill" / "TimeToSkill" / "Resources",
        repo_root / "TimeToSkill" / "Resources",
    ]

    resources_dir: Path | None = None
    for cand in candidate_roots:
        if cand.exists():
            resources_dir = cand
            break

    if resources_dir is None:
        print("[catalog-version] ERROR: Could not locate Resources directory. Checked:", file=sys.stderr)
        for cand in candidate_roots:
            print(f"  - {cand}", file=sys.stderr)
        return 0

    state_file = resources_dir / ".last_marketing_version"

    # Read MARKETING_VERSION from env (available in Xcode build phases)
    marketing_version = os.environ.get("MARKETING_VERSION", "")
    if not marketing_version:
        print("[catalog-version] MARKETING_VERSION not found in environment; skipping bump.")
        return 0

    prev_version = ""
    if state_file.exists():
        try:
            prev_version = state_file.read_text(encoding="utf-8").strip()
        except Exception:
            prev_version = ""

    if not is_version_increase(prev_version, marketing_version):
        print(f"[catalog-version] No app version increase ({prev_version} -> {marketing_version}). Skipping.")
        return 0

    # Strategy: bump by +1 only when app version increases.
    # Optional: CATALOG_VERSION_STRATEGY=map will map x.y.z -> x*10000+y*100+z
    strategy = os.environ.get("CATALOG_VERSION_STRATEGY", "bump").lower()

    # Collect all skill JSON files
    files = [resources_dir / "ExemplarySkills.json"]
    files += sorted(resources_dir.glob("ExemplarySkills_*.json"))

    updated = 0
    for path in files:
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"[catalog-version] Skip {path.name}: read error {e}")
            continue

        current = int(data.get("catalogVersion", 0))

        if strategy == "map":
            major, minor, patch = parse_version_tuple(marketing_version)
            new_version = major * 10000 + minor * 100 + patch
        else:
            new_version = current + 1

        if new_version != current:
            data["catalogVersion"] = new_version
            path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            updated += 1
            print(f"[catalog-version] {path.name}: {current} -> {new_version}")

    # Persist the last seen marketing version so we only bump once per app version
    try:
        state_file.write_text(marketing_version + "\n", encoding="utf-8")
    except Exception as e:
        print(f"[catalog-version] Warning: failed to write state file: {e}")

    print(f"[catalog-version] Done. Files updated: {updated}/{len(files)} (app {prev_version} -> {marketing_version})")
    return 0


if __name__ == "__main__":
    sys.exit(main())


