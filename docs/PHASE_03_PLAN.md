# Phase 03 Plan — Statistics Critical Fixes (Design Review)

**Release:** 1.5  
**Status:** Design only — **no implementation in this document**  
**Inputs:** `docs/STATISTICS_AUDIT.md`, current tracking philosophy  
**Date:** 2026-07-24  

---

## Project philosophy (constraints)

The tracking model stays simple:

| Rule | Implication for stats fixes |
|------|-----------------------------|
| `Skill.hours` is the persisted accumulator | Lifetime totals / rankings keep using it |
| `activeStart` marks an open session | Stats must not invent a parallel live accumulator |
| Time commits only on Stop (or manual apply) | Period stats use committed `TimeIntervalEntry` rows only |
| No background writes / no periodic persistence | Do **not** write `hours` or `lastUpdated` on a timer or scene phase |
| Battery over real-time UI | Stats refresh on appear / user open; no 1 Hz DB polling |

**Out of scope for Phase 03:** live progress-bar ticks, background timer services, ViewModel/Clean Architecture rewrites, new sync layers.

---

# Task 1 — Review `Skill.lastUpdated`

## 1.1 Every usage (code)

| Location | How it is used |
|----------|----------------|
| `Skill.swift` | Property declared; set to `Date()` **only in `init`** |
| `TrackedTimeView.swift` | Filter: `lastUpdated >= now - 7/30 days`, then sum `hours` |
| `RecentTrackingView.swift` | Same pattern (unused in UI) |
| `ActivityLogView.swift` | Sort desc + display date |
| `StatsSummaryView.swift` | `min(lastUpdated)` → “First Tracked” |

**Not used** by: Start/Stop, manual adjust, distributions, PDF skill hours, Top Skills, Counters, IAP.

There is **no** `Skill.createdAt` field today. In practice `lastUpdated` behaves as an accidental **created-at**.

## 1.2 Is each usage appropriate?

| Usage | Appropriate? | Why |
|-------|--------------|-----|
| Week/Month filter | **No** | Even if kept fresh, filtering skills then summing lifetime `hours` is the wrong metric. Period time belongs on `TimeIntervalEntry`. |
| Activity Log sort/date | **No** (as “activity”) | Activity = committed sessions, not skill creation time. |
| First Tracked | **Weak** | Only OK if product means “oldest skill created.” Wrong if it means “first session ever.” |
| Maintaining it on every Stop | **Not required** for correct stats | Would add write churn without fixing Week/Month math; violates “minimal writes” if done only for UI proxies. |

## 1.3 Alternatives

| Need | Prefer | Notes |
|------|--------|-------|
| Time in last 7/30 days | **`TimeIntervalEntry.createdAt` + `durationMinutes`** | Already written on Stop / manual apply — no new persistence path |
| Recent activity list | **`TimeIntervalEntry`** ordered by `createdAt` | One row = one commit |
| First session ever | **`min(TimeIntervalEntry.createdAt)`** | Nil/empty → “—” |
| Oldest skill created | Keep using current `lastUpdated` **or** add `createdAt` later | Today `lastUpdated` ≈ createdAt |
| Lifetime totals | **`Skill.hours`** | Unchanged philosophy |

## 1.4 Recommendation

**Remove `lastUpdated` from Statistics calculations** (Week, Month, Activity Log, First Tracked-as-activity).

**Do not** add Stop/manual hooks solely to keep `lastUpdated` warm for stats — that is unnecessary state synchronization.

**Schema for 1.5 (preferred minimal risk):**

- **Leave the property on `Skill`** (avoid SwiftData migration in this release).
- **Stop reading it in stats views.**
- Optionally treat it later as deprecated / rename to `createdAt` in a dedicated migration phase (not required for 03A–03C).

| Option | Verdict |
|--------|---------|
| Remain as live “last activity” field | **Reject** for 1.5 — not needed if entries drive period/activity |
| Repurpose as created-at (docs + labels only) | **Acceptable** interim if Summary keeps a creation date card |
| Remove from statistics | **Recommend** |
| Delete property from model now | **Defer** — migration risk > benefit for 1.5 |

---

# Task 2 — Correct Statistics model (source of truth)

Active (running) time remains **intentionally excluded** from all numeric totals until Stop — consistent with commit-on-stop.

### Source-of-truth matrix

| Section | Correct source of truth | Why |
|---------|-------------------------|-----|
| **Lifetime totals** (Summary “Total Hours”, Tracked Time “Total”) | **`Skill.hours`** (sum) | Canonical persisted accumulator; matches tracker UI after commit |
| **Weekly tracked time** (rolling last 7 days *or* calendar week — pick one in Task 3) | **`TimeIntervalEntry`**: sum `durationMinutes` where `createdAt` in range | Only durable per-session timestamps; includes timer + manual commits |
| **Monthly tracked time** (rolling 30 days *or* calendar month) | Same as weekly with different range | Same reason |
| **Percentages** (Week/Month vs Total) | Period sum from entries ÷ lifetime sum from **`Skill.hours`** (guard ÷0) | Period ≠ subset of skill filter; lifetime stays on `hours`. Cap display at 100% if entries ever exceed hours (divergence edge case) |
| **Top Skills** | **`Skill.hours`** | Lifetime ranking; simple; matches product “who has the most accumulated time” |
| **Activity Log** | **`TimeIntervalEntry`** (latest N by `createdAt`) | Real commits; show skill name (lookup by `skillId`), duration, timestamp, optional source |
| **Summary: skill count** | **`Skill` count** | Unchanged |
| **Summary: active timers** | **`Skill.activeStart != nil` count** | Unchanged; display-only |
| **Summary: first tracked** | **`min(TimeIntervalEntry.createdAt)`** preferred; else relabel creation card using legacy `lastUpdated` | “First session” vs “Oldest skill” — pick one label (Task 3) |
| **Global Distribution** | **`TimeIntervalEntry`** (all, or optional date filter later) | Session-**length** histogram (not calendar fill). Keep current intent |
| **Per-skill Distribution** | **`TimeIntervalEntry` where `skillId` matches** | Same as today, correct source |
| **PDF: skill list hours** | **`Skill.hours`** | Lifetime report lines |
| **PDF: counters** | **`Counter`** | Unrelated to time model; keep |
| **PDF: histograms** | **`TimeIntervalEntry`** | Same as Global / per-skill UI |

### Explicit non-sources

| Do not use for… | Field |
|-----------------|-------|
| Period tracked time | `Skill.lastUpdated`, `Skill.hours` (as the filtered sum) |
| Activity recency | `Skill.lastUpdated` |
| Live in-progress hours in stats | `Date() - activeStart` (optional future *display-only* badge; not 1.5 persistence) |

### Minimal compute approach (aligned with philosophy)

- Stats sheet already loads `[Skill]` via `@Query`.
- Add a **read-only** fetch of `[TimeIntervalEntry]` when the sheet appears (or pass from parent once).
- Pure functions: `sumDuration(entries:in:)` — no writes, no timers, no caches that must be synced back to SwiftData.
- Histograms can keep `onAppear` load; optional refresh when sheet re-opens is enough for battery.

---

# Task 3 — Product terminology

Do **not** change `Localizable.strings` in implementation phases until copy is approved. This section only recommends.

| Current label (EN) | Ambiguity | Recommended direction |
|--------------------|-----------|------------------------|
| **Week** | Calendar week vs last 7 days | Prefer **“Last 7 Days”** if keeping rolling window (smallest logic). If calendar week: **“This Week”** and implement week boundaries. |
| **Month** | Calendar month vs last 30 days | Prefer **“Last 30 Days”** *or* **“This Month”** with calendar month — do not keep bare **“Month”**. |
| **Total** (Tracked Time card) | Total of what? | **“All Time”** or **“Lifetime”** to mirror Summary. |
| **Tracked Time** (section) | Could mean live timer | OK if subtitle clarifies committed time only; optional **“Committed Time”** — probably overkill. |
| **Total Hours** (Summary) | Same | **“Lifetime Hours”** or keep + rely on section context. |
| **First Tracked** | First session vs skill created | If using entries: **“First Session”**. If keeping creation date: **“Oldest Skill”**. |
| **Activity Log** | Sounds like a feed of sessions | Keep title; ensure rows are sessions. Empty copy already says “No recent activity.” |
| **Global Time Distribution** | Sounds like time-of-day or calendar | Prefer **“Session Length Distribution”** (or subtitle: “How long your sessions are”). |
| **Total time** (distribution) | Lifetime hours from entries vs `Skill.hours` | Subtitle: **“Sum of recorded sessions”** — may diverge from Lifetime Hours (known; fix divergence in later phase). |
| **Mean interval / Std dev** | OK for power users | Keep; optional footnote “per session”. |
| **Top Skills** | OK | Keep (lifetime). |
| Overview title **Skill Progress Overview** | Fine | Keep. |

### 1.5 product decision (recommend default)

For **smallest correct fix** and philosophy fit:

- Week card → **rolling last 7 days** of committed entry durations.  
- Month card → **rolling last 30 days**.  
- Labels → **“Last 7 Days” / “Last 30 Days” / “All Time”**.  
- Calendar week/month/year → **later phase** if product wants them.

Active timers: keep counting; do not add “includes running time” unless product explicitly asks (would be display-only math, still no writes).

---

# Task 4 — Implementation roadmap

Principles per phase: **smallest diff**, **independently testable**, **low regression risk**, **no new persistence behavior** beyond what Stop/manual already do.

---

## Phase 03A — Fix Tracked Time period cards (critical)

**Goal:** Week/Month show committed time in rolling windows; Total stays on `Skill.hours`.

**Touch (expected):**

- `TrackedTimeView.swift` (primary)
- Possibly `StatsView.swift` only if entries must be fetched once and passed down

**Do:**

1. Fetch or receive `[TimeIntervalEntry]`.
2. Replace `trackedHours(forDays:)` with sum of `durationMinutes` where `createdAt >= now - N days` (use `Calendar.current`).
3. Keep Total = sum of `Skill.hours`.
4. Fix ÷0 without `max(total, 0.01)` fake hours (use guarded percentage).
5. **Do not** update `lastUpdated` in this phase.

**Do not:** localization key renames yet (can ship correct math under old “Week”/“Month” labels briefly, or bundle 03D).

**Test:**

- No entries → Week/Month 0; Total matches skills.
- Stop a timer → Week increases by ~session length; `Skill.hours` Total increases same amount.
- Old skill, new session → Week reflects session only, not lifetime hours.
- Manual adjust → included via `.manual` entry.
- Running timer (not stopped) → Week unchanged.

**Exit:** Audit S-1 / S-4 / S-8 addressed for Tracked Time.

---

## Phase 03B — Fix Activity Log + Summary “First …” card

**Goal:** Activity reflects real commits; First card uses a defined source.

**Touch:**

- `ActivityLogView.swift`
- `StatsSummaryView.swift`
- `StatsView.swift` (pass entries if needed)

**Do:**

1. Activity Log: latest N `TimeIntervalEntry` by `createdAt` (e.g. 5–10); resolve skill name via `skills` id map; show duration + date.
2. Summary date card: `min(entry.createdAt)` as **First Session**, or if no entries show “—”.
3. Stop using `lastUpdated` in these views.

**Test:**

- Create skill, no sessions → no fake activity from creation time.
- Stop timer → log row appears with ~duration.
- Manual adjust → log row appears.

**Exit:** Audit S-6 / S-7 (stats side).

---

## Phase 03C — Label clarity (copy only)

**Goal:** Remove ambiguity without logic churn.

**Touch:** `Localizable.strings` (and locale files as needed) — keys for Week/Month/Total/First/Distribution titles.

**Do:** Apply Task 3 approved strings (recommend Last 7 Days / Last 30 Days / All Time / First Session / Session Length Distribution).

**Test:** Spot-check EN (+ one other locale if process requires).

**Exit:** Audit S-3 terminology.

---

## Phase 03D — Distribution hygiene (optional for 1.5)

**Goal:** Small correctness/UX fixes without architecture change.

**Touch:** `GlobalTimeDistributionView.swift`, `TimeDistributionView.swift`, optionally shared helper extracted **once** if duplication is painful (keep helper pure/stateless).

**Do (pick subset):**

- Refresh on `onAppear` only remains OK; optionally re-fetch when Stats sheet appears again (already true if view recreated).
- Fix bin edge construction when `maxVal < 960` (monotonic edges).
- Document in UI that totals are sum of sessions (may differ from Lifetime if history diverged).

**Defer if tight:** full `hours` ↔ entries reconciliation (reset/delete/negative adjust) — separate phase (03F).

---

## Phase 03E — Dead code / comment cleanup (optional)

**Touch:** `RecentTrackingView.swift` (remove or leave unused), comments in `TrackedTimeView`.

**Risk:** very low. Can ship after 03A–03C.

---

## Phase 03F — Data integrity (post-1.5 candidate)

**Goal:** Align `Skill.hours` and entries over time.

**Examples:** delete entries on skill delete; on reset clear or tombstone entries; signed manual adjustments.

**Risk:** higher; needs careful migration/product rules. **Not required** to make Week/Month correct if new sessions are consistent going forward.

**Also defer:** deleting/renaming `Skill.lastUpdated` schema field.

---

## Phase 03G — Calendar ranges (post-1.5 candidate)

Today / Yesterday / This Week (locale week start) / Last Week / This Month / Last Month / This Year — only after rolling windows + labels are correct. Still read-only entry aggregation; still no background writes.

---

## Suggested 1.5 ship set

| Must ship | Nice | Later |
|----------|------|-------|
| **03A** | 03D (bin edges) | 03F integrity |
| **03B** | 03E dead code | 03G calendar ranges |
| **03C** | | Schema removal of `lastUpdated` |

---

## Dependency graph

```text
03A (Tracked Time math)
  └─► 03C (labels)          // can parallelize after copy freeze
03B (Activity + First)      // independent of 03A; both need entry fetch — share helper carefully
03D / 03E                   // after 03A or parallel if no shared helper conflict
03F / 03G                   // after 1.5
```

Shared optional artifact (still philosophy-safe): one file e.g. `StatsTimeAggregates.swift` with pure functions:

- `func committedHours(in entries: [TimeIntervalEntry], since: Date, now: Date = .now) -> Double`
- `func lifetimeHours(skills: [Skill]) -> Double`

No ObservableObject, no timers, no writes.

---

## Explicit non-goals (reject in review)

1. Writing `lastUpdated` on Stop “to fix stats.”  
2. Background or periodic SwiftData writes.  
3. Using live `activeStart` elapsed inside Week/Month totals for 1.5.  
4. Replacing `Skill.hours` with sum-of-entries for lifetime Top Skills / Summary in 1.5.  
5. Large stats framework / MVVM rewrite.

---

## Decision log (for implementers)

| Decision | Choice |
|----------|--------|
| Period source of truth | `TimeIntervalEntry` |
| Lifetime source of truth | `Skill.hours` |
| `lastUpdated` in stats | **Stop using**; keep property unused for now |
| Active sessions in totals | **Excluded** until Stop |
| Default period shape | Rolling **7 / 30 days** |
| Label update timing | Phase **03C** (after or with 03A) |
| Schema migration | **Not** in 03A–03C |

---

## References

- `docs/STATISTICS_AUDIT.md` — confirmed bugs S-1…S-12  
- Tracking philosophy — this document header  
- Models: `Skill.swift`, `TimeIntervalEntry.swift`  
- UI: `StatsView.swift`, `TrackedTimeView.swift`, `ActivityLogView.swift`, `StatsSummaryView.swift`, distribution + PDF views  
