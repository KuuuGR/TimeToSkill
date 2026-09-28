# Statistics Module Audit — TimeToSkill

**Scope:** “Your Statistics” (`StatsView`) and related surfaces (per-skill distribution, PDF export histograms).  
**Method:** Static code review only. No code was modified.  
**Date of audit:** 2026-07-24  

---

## Executive verdict

The Statistics module does **not** implement calendar ranges such as Today / Yesterday / This Week / Last Week / calendar Month / Year. What exists is a small set of lifetime + rolling-window cards that mostly read **`Skill.hours`** and **`Skill.lastUpdated`**, plus a session-length histogram that reads **`TimeIntervalEntry`**.

**Confirmed:** the “Tracked Time → Week” value is mathematically and semantically incorrect for any reasonable definition of “time tracked this week.”

---

## Module map

| UI surface | Entry | Files |
|------------|-------|-------|
| Your Statistics sheet | Main FAB → `StatsView` | `StatsView.swift` |
| Summary | embedded | `StatsSummaryView.swift`, `StatCard.swift` |
| Top Skills | embedded | `TopSkillsView.swift`, `ProgressBarCompact.swift` |
| Tracked Time | embedded | `TrackedTimeView.swift` |
| Activity Log | embedded | `ActivityLogView.swift` |
| Global Time Distribution | embedded | `GlobalTimeDistributionView.swift` |
| Per-skill distribution | Skill options → Distribution | `TimeDistributionView.swift` |
| PDF export histograms | Options → Export PDF | `OptionsView.swift` |
| Unused sibling | **not shown in Stats** | `RecentTrackingView.swift` |

`Counter` data appears in PDF export only, **not** in the Statistics sheet.

**Streaks:** none implemented.

---

## Data sources cross-check

| Source | Used by Statistics? | Appropriate? |
|--------|---------------------|--------------|
| **`Skill.hours`** | Summary totals, Top Skills, Tracked Time cards, Activity Log value, PDF skill list | Appropriate for **lifetime totals / rankings**. **Not** appropriate for period filters. |
| **`Skill.lastUpdated`** | Tracked Time Week/Month filter, Activity Log ordering/date, Summary “First Tracked” | **Inappropriate** as implemented: set **only in `Skill.init`**, never updated on timer stop or manual adjust. |
| **`Skill.activeStart`** | Summary “Active Timers” count only | Appropriate for counting running timers. Active elapsed is **excluded** from all hour totals (commit-on-stop). |
| **`TimeIntervalEntry`** | Global / per-skill histograms + means/stddev; PDF histograms | Appropriate for **session-length distribution**. Has `createdAt` but **no stats UI filters by `createdAt`**. Includes both `.timer` and `.manual` sources. |
| **`Counter`** | PDF only | N/A for time stats. |
| Cached values | None beyond `@State` histogram caches loaded `onAppear` | Histograms can go stale until reopen if sheet stays open while tracking. |

### Why each source was likely chosen

- **`Skill.hours`:** simple lifetime accumulator; easy for totals/rankings.
- **`lastUpdated`:** intended as “recent activity” proxy for Week/Month — **but never maintained**, so the proxy is broken.
- **`TimeIntervalEntry`:** added later for distribution charts; not wired into Tracked Time Week/Month.

---

## Section-by-section analysis

### 1. Summary (`StatsSummaryView`)

| Metric | Data | Calculation | Timer sessions | Manual edits | Active timers |
|--------|------|-------------|----------------|--------------|---------------|
| Total Hours | `Skill.hours` sum | `reduce(+)` then `Int(h)` + fractional minutes | Included **after Stop** | Included when applied | **Excluded** (not yet in `hours`) |
| Skills | skill count | `skills.count` | N/A | N/A | N/A |
| Active Timers | `activeStart != nil` | count | N/A | N/A | Counted as active, hours not added |
| First Tracked | `min(lastUpdated)` | earliest `lastUpdated` | **Wrong field** | Same | N/A |

**SwiftData:** `@Query` all `Skill` in `StatsView` — no predicate/date filter.

**Correctness:**

- Total Hours ≈ lifetime persisted hours — **OK** if interpreted as lifetime (label says “Total Hours”).
- First Tracked uses creation-time `lastUpdated` — **misleading** (closer to “oldest skill created”, and only if skills weren’t migrated oddly). Not “first time any tracking occurred.”

---

### 2. Top Skills (`TopSkillsView`)

| Metric | Data | Calculation |
|--------|------|-------------|
| Ranking | `Skill.hours` | sort descending, `prefix(3)` |
| Display hours | `Skill.hours` | `Xh Ym` truncation |
| Compact bar | `Skill.hours` | same stage fractions as tracker UI |

**Includes:** completed timer commits + manual adjusts (via `hours`).  
**Excludes:** live active session.  
**Counters:** no.

**Mathematically:** ranking by lifetime hours is consistent. Ties are unstable (sort not secondary-keyed). Truncation toward zero for display (e.g. 1.9h → `1h 54m` OK; negative hours possible after negative manual adjust).

---

### 3. Tracked Time (`TrackedTimeView`) — primary bug area

Labels (EN): **Week**, **Month**, **Total** (`stats_week_label` / `stats_month_label` / `stats_total_label`).

**There is no Picker** despite the file comment (“using Picker”). Three cards are always shown.

#### Week card

```swift
trackedHours(forDays: 7)
// cutoff = now - 7 days
// filter skills where lastUpdated >= cutoff
// sum those skills' FULL Skill.hours
```

#### Month card

Same with `forDays: 30`.

#### Total card

Sum of all `Skill.hours`, with `max(total, 0.01)` floor (and NaN guard). Empty state shows **0.01 h**, not 0.

#### Percentages

`weekOrMonthHours / totalHours * 100`, displayed as integer percent. Total subtext hard-coded `"100%"`.

Because Week/Month can equal Total when every skill’s `lastUpdated` falls in the window (almost always — see below), percentages often show **100%** for Week and Month.

---

### 4. Activity Log (`ActivityLogView`)

| Field | Source | Issue |
|-------|--------|-------|
| Which 3 skills | sort by `lastUpdated` desc | Stale — reflects creation order/time, not recent tracking |
| Date shown | `lastUpdated` | Same |
| Hours shown | full `Skill.hours` | Lifetime total, not “activity amount” |

---

### 5. Global Time Distribution (`GlobalTimeDistributionView`)

| Metric | Source | Calculation |
|--------|--------|-------------|
| Entries | `FetchDescriptor<TimeIntervalEntry>()` — **unfiltered** | all rows |
| Total time | sum `durationMinutes` / 60 | hours string |
| Mean | average of interval lengths (minutes) | per **entry**, not per day |
| Std dev | population σ (`/ n`) | of interval lengths |
| Histogram | count of entries per duration bin | see bin edges below |

**Includes:** `.timer` and `.manual` (no source filter).  
**Excludes:** in-progress timers (no entry until Stop).  
**Does not use:** `createdAt` for any time range. This is “all-time distribution of **session lengths**,” not “time spent over calendar periods.”

**Orphans:** entries for deleted skills remain and still count.

**PDF:** same binning/fetch logic in `OptionsView`.

---

### 6. Per-skill Time Distribution (`TimeDistributionView`)

Same math as global, filtered by `skillId == skill.id`. Same include/exclude rules.

**Reworked since this audit:** the view reads its rows through a skill-filtered `@Query` (instead of a one-off `onAppear` fetch), so it stays current while the options sheet is open — **fixes S-9 for this view** — and buckets use fixed edges with a trailing `≥ 960m` bucket instead of `[…, 960, maxVal + 1]`, which removes the invalid interval — **fixes S-10 for this view**. The layout is now a horizontal bar chart (label · track + fill · count · share) with an empty state; `GlobalTimeDistributionView` and the PDF export still use the old binning.

**Window sizing:** on macOS the histogram is rendered without a surrounding `ScrollView` so the options sheet can size itself to the chart (a macOS sheet fits its content, and a `ScrollView` has no intrinsic height — the window used to shrink to a strip around the title bar). The window therefore grows until the last bucket is visible and keeps the same 16 pt inset above the skill name and below the histogram. iOS keeps the scroll view.

---

### 7. PDF export (Options)

| Section | Source |
|---------|--------|
| Skill list | `Skill.name` + `Skill.hours` |
| Counters | `Counter` title/value/thresholds |
| Global histogram | all `TimeIntervalEntry` |
| Per-skill histograms | entries by `skillId` |

No Week/Month stats in PDF. No streaks.

---

### 8. Unused `RecentTrackingView`

Same broken pattern as Tracked Time (filter `lastUpdated`, sum full `hours`), labels hard-coded “This Week” / “This Month” for last 7/30 days. **Not mounted in `StatsView`.**

---

## Time filters — requested ranges vs reality

| Requested range | Implemented? | Actual behavior if any |
|-----------------|--------------|------------------------|
| Today | **No** | — |
| Yesterday | **No** | — |
| This Week (calendar week) | **No** | UI says “Week” but means rolling 7×24h via `Date() - 7 days` |
| Last Week | **No** | — |
| This Month (calendar) | **No** | UI says “Month” but means rolling 30×24h |
| Last Month | **No** | — |
| This Year | **No** | — |
| All Time | **Partial** | Summary Total Hours, Tracked Time Total, distribution totals |

### How “Week” / “Month” are actually calculated

```text
cutoff = Calendar.current.date(byAdding: .day, value: -7|-30, to: Date())!
include skill if skill.lastUpdated >= cutoff
value = sum(skill.hours)   // lifetime hours, NOT hours in window
```

| Concern | Behavior |
|---------|----------|
| First day of week | **Irrelevant** — no week-boundary API (`startOfWeek`, `weekday`) used |
| Locale / calendar | `Calendar.current` only used for `date(byAdding: .day)` |
| Timezone | Device calendar/timezone; cutoff is an absolute `Date` instant |
| DST | Day add uses calendar days; window length in hours can be 167/168/169 around DST — secondary vs the main logic bugs |
| Start of day | **Not** normalized; window is “now minus N days” to now |

**Conclusion:** even if `lastUpdated` were maintained correctly, this still would **not** be “hours tracked in the last 7 days”; it would be “lifetime hours of skills touched in the last 7 days.”

---

## Special investigation: Tracked Time “Week”

### Is it incorrect?

**Yes — confirmed bug.**

### Why (two independent failures)

**Failure A — wrong quantity after filter**

Filter selects skills, then sums **entire lifetime `Skill.hours`**.  
Example: skill with 500h lifetime, last touched yesterday → **Week shows 500h**, not hours logged this week.

**Failure B — `lastUpdated` never updates**

```swift
// Skill.init only:
self.lastUpdated = Date()
```

Timer stop (`StartView.toggleTimer`) and manual adjust (`SkillOptionsSheet.applyTimeChange`) **do not** assign `lastUpdated`.

So the filter does **not** mean “recently tracked.” It means “skill whose **creation** timestamp falls within the last 7/30 days” (for normal app usage).

### Under which circumstances

| Scenario | Week card tends to show |
|----------|-------------------------|
| All skills created >7 days ago; user tracks heavily this week | **0.0 h** (filter excludes everyone) while Total ≫ 0 — **very suspicious** |
| Skill created 2 days ago with any hours (even old migrated value) | Full lifetime hours of that skill |
| Only skills ever created are within 7 days | Week ≈ Total (often 100%) |
| Active timer running, not stopped | Week unchanged (hours not committed) |
| Manual adjust this week on old skill | Week **unchanged** (`lastUpdated` stale); Total increases |

### Responsible code

1. `TrackedTimeView.trackedHours(forDays:)` — wrong metric + wrong date field  
2. `Skill.swift` — `lastUpdated` only set in `init`  
3. `StartView.toggleTimer` / `SkillOptionsSheet.applyTimeChange` — omit `lastUpdated` updates  
4. Labels imply calendar Week/Month; implementation is rolling days  

Same pattern in unused `RecentTrackingView`.

---

## Totals / charts / percentages — correctness matrix

| Displayed value | Mathematically OK for its formula? | Matches user-facing intent? |
|-----------------|------------------------------------|-----------------------------|
| Summary Total Hours | Yes (sum of doubles) | Yes if “lifetime persisted” |
| Summary skill count | Yes | Yes |
| Active timers | Yes | Yes |
| First Tracked | Yes as `min(lastUpdated)` | **No** — not first tracking event |
| Top 3 hours / bars | Yes | Yes (lifetime) |
| Tracked Time Week | Formula consistent but **wrong inputs/meaning** | **No** |
| Tracked Time Month | Same | **No** |
| Tracked Time Total | Yes, except empty floor `0.01` | Mostly; empty UX odd |
| Week/Month % of Total | Arithmetic OK | **Misleading** when Week≈Total or Week=0 incorrectly |
| Activity Log | Sort/format OK | **No** — not recent activity |
| Distribution total/mean/σ | OK as session-length stats (population σ) | OK if labeled as interval stats; easy to misread as “time this period” |
| Histogram bin counts | OK when edges monotonic | Edge list can append `maxVal+1` after `960`, creating an empty inverted bin when `maxVal < 960` (usually filtered out) |
| PDF skill hours | Same as Summary | Yes (lifetime) |
| PDF histograms | Same as UI distribution | Same caveats + orphans |
| Streaks | N/A | Not present |

### Manual vs timer inclusion

| Surface | Timer (after Stop) | Manual adjust | Active (running) |
|---------|--------------------|---------------|------------------|
| Skill.hours-based cards | Yes | Yes | No |
| TimeIntervalEntry histograms | Yes (`.timer`) | Yes (`.manual`, **absolute** minutes even if hours went down) | No |

**Extra inconsistency:** negative manual adjust **decreases** `Skill.hours` but still inserts a **positive** `TimeIntervalEntry` (`abs(...)`). Distribution totals can **exceed** Summary Total Hours; resets zero `hours` without deleting entries → distributions still show old sessions.

---

## Confirmed bugs

| ID | Severity | Issue | Affected files |
|----|----------|-------|----------------|
| **S-1** | **Critical** | Tracked Time Week/Month sum **lifetime** `hours` for skills passing a date filter — not period-tracked time | `TrackedTimeView.swift` |
| **S-2** | **Critical** | `lastUpdated` never updated after create → Week/Month/Activity Log/First Tracked all wrong | `Skill.swift`, `StartView.swift`, `SkillOptionsSheet.swift`, `TrackedTimeView.swift`, `ActivityLogView.swift`, `StatsSummaryView.swift` |
| **S-3** | **High** | Labels “Week”/“Month” ≠ calendar week/month; implementation is rolling 7/30 days (and still wrong per S-1/S-2) | `TrackedTimeView.swift`, `Localizable.strings` |
| **S-4** | **High** | Period stats ignore `TimeIntervalEntry.createdAt`, the only durable per-session timestamp | `TrackedTimeView.swift` (and absence of a proper aggregator) |
| **S-5** | **High** | `Skill.hours` vs Σ `TimeIntervalEntry` can diverge (reset, negative adjust + abs entry, orphans, pre-entry history) | `SkillOptionsSheet.swift`, `StartView.swift`, delete path, distribution views |
| **S-6** | **Medium** | Activity Log presents lifetime hours + stale dates as “activity” | `ActivityLogView.swift` |
| **S-7** | **Medium** | First Tracked ≠ first tracking; uses `min(lastUpdated)` | `StatsSummaryView.swift` |
| **S-8** | **Medium** | Tracked Time Total uses `max(total, 0.01)` — empty/zero shows 0.01 h and distorts % | `TrackedTimeView.swift` |
| **S-9** | **Medium** | Histograms/`onAppear` only — stale while Stats sheet remains open (`TimeDistributionView` now uses `@Query`) | `GlobalTimeDistributionView.swift` |
| **S-10** | **Low** | Histogram edges `[…, 960, maxVal+1]` when `maxVal < 960` create invalid interval (usually empty) (`TimeDistributionView` now uses fixed edges) | `GlobalTimeDistributionView.swift` + `OptionsView` |
| **S-11** | **Low** | Dead duplicate logic in `RecentTrackingView` (same bugs, unused) | `RecentTrackingView.swift` |
| **S-12** | **Low** | File comment claims Picker; no picker exists | `TrackedTimeView.swift` |

---

## Suspected bugs / product gaps

| ID | Severity | Issue | Notes |
|----|----------|-------|-------|
| **S-13** | Medium | Missing Today/Yesterday/Last Week/Last Month/This Year | Not bugs in code paths — **unimplemented** relative to expected analytics UX |
| **S-14** | Low | Population vs sample stddev | Fine for descriptive UI; clarify label if users expect sample σ |
| **S-15** | Low | Nested `ScrollView` inside Stats `ScrollView` for global histogram | UX/scroll gesture oddity, not wrong math |
| **S-16** | Low | Top Skills tie order nondeterministic | Minor |

---

## Recommended fixes (do not implement yet)

1. **Period totals (Week/Month/etc.):** sum `TimeIntervalEntry.durationMinutes` where `createdAt` ∈ range; convert to hours. Do **not** filter `Skill` by `lastUpdated` then sum `Skill.hours`.
2. **Maintain or drop `lastUpdated`:** either update on every hours change / stop, or remove from stats and use entry `createdAt` / skill `createdAt` (add field if needed).
3. **Define ranges explicitly:** calendar `startOfDay` / `dateInterval(of: .weekOfYear|.month|.year)` with `Calendar.current`, plus separate rolling windows if desired; localize labels to match.
4. **Active timers:** decide product rule — exclude (current) vs include live `now - activeStart` in period/total; document in UI.
5. **Reconcile hours vs entries:** on reset/delete/negative adjust, update or tombstone entries so Summary and Distribution stay consistent.
6. **Activity Log:** list recent `TimeIntervalEntry` rows (or skills ordered by max entry `createdAt`), show session duration not lifetime hours.
7. **Remove `0.01` floor** or only use it inside percentage guard.
8. **Refresh histograms** when sheet appears / scene active / data changes (`onChange` of query counts).

---

## Prioritized issue list (most → least critical)

1. **S-1 + S-4** — Tracked Time Week/Month compute the wrong metric (lifetime hours, not period sessions).  
2. **S-2** — `lastUpdated` stale forever → Week/Month filter + Activity Log + First Tracked unreliable.  
3. **S-3** — Calendar wording vs rolling 7/30-day window.  
4. **S-5** — `Skill.hours` and `TimeIntervalEntry` divergence (reset / abs(manual) / orphans).  
5. **S-6 / S-7** — Activity Log & First Tracked semantics wrong.  
6. **S-8** — `0.01` hour floor skews Total and percentages.  
7. **S-9** — Stale distribution while sheet open.  
8. **S-13** — Missing real calendar ranges (Today … This Year) if product expects them.  
9. **S-10 / S-11 / S-12 / S-14–S-16** — Histogram edge case, dead code, comments, minor UX/math nits.

---

## Appendix: intended vs actual (Tracked Time Week)

```text
Intended (typical product meaning):
  sum(duration of sessions with createdAt in [weekStart, now))
  including timer stops + manual entries in that window
  excluding (or separately showing) active uncommitted time

Actual:
  skills = all Skill via @Query
  cutoff = now - 7 days
  skills.filter { lastUpdated >= cutoff }   // lastUpdated == createdAt in practice
    .map(\.hours)                            // lifetime totals
    .sum()
```

This matches the reported suspicion: **“This Week” / Week tracked time is incorrect.**
