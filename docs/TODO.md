# Backlog

Work items use stable `T4S-xxx` IDs. One status per item:
OPEN / IN PROGRESS / BLOCKED / DEFERRED / DONE / WONTFIX.
DONE requires a commit and the check that verified it. This file is the
authoritative backlog; chat is not.

## T4S-001 — Per-skill session distribution chart

- Status: IN PROGRESS
- Source: architect prompt, 2026-10-18. Direct entry from the skill progress
  row; equal-width horizontal histogram of completed timer sessions; optional
  translucent normal reference curve.
- Not committed. The working tree contains the implementation and is waiting
  for architect review.
- One shared calculation (`SessionDurationHistogram`) is compiled into both
  `Time4Skill` and `Time4SkillMacOS`. Only the sheet layout differs: iOS
  opens it from the skill row with Done in the navigation bar; macOS uses
  the wider sheet.

### Metric

Completed timer sessions for one skill. A sample value is a
`TimeIntervalEntry` whose `skillId` matches the skill, whose `source` is
`.timer`, and whose `durationMinutes` is finite and greater than zero.
Manual entries stay in accumulated skill time, the global distribution, and
the PDF. They are not sessions on this chart.

- Count: number of values in that sample.
- Mean: arithmetic mean, μ = (Σ x) / n.
- Reference curve: sample standard deviation,
  s = sqrt(Σ (x − μ)² / (n − 1)).
  Expected count in a bin [a, b) is n × (Φ((b − μ) / s) − Φ((a − μ) / s)),
  where Φ(z) = 0.5 × (1 + erf(z / sqrt(2))).
- The curve is hidden when n < 10 or when s is zero or non-finite. It is a
  visual reference, not a claim that the sessions are normal and not a
  prediction.

### Acceptance criteria

1. The chart opens from the skill progress row.
2. It counts completed timer sessions and excludes manual adjustments.
3. The global distribution and the PDF keep their current samples and bins.
4. Bin width is one of 5, 15, 30, and 60 minutes. The default is 15, because
   the previous per-skill chart used 5-minute bins only below 15 minutes.
5. Regular bins keep the selected width. At most 512 of them are drawn.
   Sessions beyond that edge are counted once in an explicit overflow bin
   labeled from its lower boundary, such as `≥ 2560 min` for a 5-minute
   width. The overflow bin is not described as having the regular width.
   Its reference frequency, when the curve is shown, is the normal
   probability from that boundary to positive infinity.
6. The curve uses the integrated frequency above and is hidden for n < 10 or
   for a zero or non-finite sample standard deviation.
7. New copy is in every `Localizable.strings`. Non-English locales currently
   use the English source text, because a missing key in an existing `.lproj`
   is shown as the raw key. The chart control and the selected bin width have
   accessibility labels.
8. No SwiftData schema change and no migration.
9. Timers, manual adjustments, counters, and the other statistics are unchanged.
10. Validation is the pure calculation checks plus the iOS `Time4Skill` and
    macOS `Time4SkillMacOS` Release builds. A successful build does not
    validate the curve and is not App Store acceptance.

### Verification

- Host-side calculation check passed after the overflow-bin change: empty,
  manual, unrecognized source, non-finite values, n = 9, constant sample,
  exact bin edge, a session past 512 regular bins, a 1e20-minute session,
  sample standard deviation, Φ(1.5) − Φ(0), and a normal tail from the mean.
- `SessionDurationHistogramTests` contains those cases and was not launched.
  The iOS test target needs a simulator.
- `Time4SkillMacOS` Release was built after the overflow-bin change and
  succeeded. The chart was not opened. A successful build does not validate
  the curve.
- `Implemented in:` not set. There is no commit yet. Status stays IN PROGRESS.

## T4S-002 — Research-backed theory and milestones

- Status: IN PROGRESS
- Source: architect prompt, 2026-10-18. Six supplied topics, progressive
  disclosure, and the existing 100 / 1,000 / 10,000 hour marks labeled as
  progress milestones. The 21-hour progress band is unchanged.
- The working tree contains the screen. It is not committed.
- Supplied citations, study context, findings, and limitations are bundled
  in `TheoryCatalog` and `Localizable.strings`. Non-English locales use the
  English source text so a missing key is not shown as a raw identifier.
- `Implemented in:` not set.
- `Verified by:` Release builds of both app targets. The screen was not opened.

## T4S-003 — Aggregate yearly activity calendar

- Status: IN PROGRESS
- Source: architect prompt, 2026-10-18. One calendar for all skills.
  Daily score is `S + min(M / 60, 0.99)` from completed timer sessions
  ending on the local day. Manual entries are excluded. Levels 0–5 are
  display only and are not shown as numbers.
- The working tree contains the calendar in Statistics. It is not committed.
- Non-English locales use the English source text so a missing key is not
  shown as a raw identifier.
- `Implemented in:` not set.
- Host-side score and calendar checks passed. `Time4Skill` and
  `Time4SkillMacOS` Release builds succeeded. The screen was not opened.
