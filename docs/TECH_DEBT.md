# Technical Debt — TimeToSkill

Prioritized list for future work. **Do not treat this as an implementation checklist for this audit** — documentation only.

Severity scale: **Critical** → **High** → **Medium** → **Low**.

---

## Critical

### TD-01 — Wire IAP entitlements to Pro feature flags

| | |
|--|--|
| **Severity** | Critical |
| **Description** | `IAPManager.isPurchased` is never synced to `@AppStorage("customSkillUnlocked")` (or feature checks never read `isPurchased`). |
| **Why it matters** | Paying customers may not receive Pro features; revenue and App Review trust at risk. |
| **Suggested solution** | Single source of truth from StoreKit entitlements; on `isPurchased == true`, unlock features (and restore on launch). Prefer reading `iap.isPurchased` directly in UI instead of a separate AppStorage flag. |

### TD-02 — Fix skill activity timestamps & weekly stats semantics

| | |
|--|--|
| **Severity** | Critical |
| **Description** | `lastUpdated` unused after init; week/month stats sum lifetime hours for recently touched skills. |
| **Why it matters** | Statistics are misleading; users cannot trust progress insights. |
| **Suggested solution** | Update `lastUpdated` on every hours change; compute period totals from `TimeIntervalEntry.createdAt` + `durationMinutes`. |

### TD-03 — Cascade or clean up interval entries on skill delete

| | |
|--|--|
| **Severity** | Critical |
| **Description** | Soft UUID link leaves orphans. |
| **Why it matters** | Corrupts global analytics/PDF over time. |
| **Suggested solution** | SwiftData `@Relationship` with cascade delete, or explicit delete of matching entries in the delete path. |

---

## High

### TD-04 — Repair automated tests

| | |
|--|--|
| **Severity** | High |
| **Description** | Unit color assertions and UITest button labels are stale; meaningful timer UITest commented out. |
| **Why it matters** | CI cannot gate regressions; false confidence. |
| **Suggested solution** | Update assertions to design tokens; use accessibility identifiers (already partially present) instead of visible English titles; add in-memory SwiftData fixtures. |

### TD-05 — Align privacy / offline claims with StoreKit reality

| | |
|--|--|
| **Severity** | High |
| **Description** | Multiple privacy docs disagree; FAQ says no internet. |
| **Why it matters** | App Store / legal inconsistency. |
| **Suggested solution** | Single privacy source of truth; state that tracking data stays on-device while IAP uses Apple’s network. |

### TD-06 — Navigation architecture cleanup

| | |
|--|--|
| **Severity** | High |
| **Description** | Nested stacks + splash `fullScreenCover` root. |
| **Why it matters** | Blocks scalable navigation, deep links, state restoration. |
| **Suggested solution** | One app-level `NavigationStack` + path; replace splash with root `@State` enum (`splash` / `main`). |

### TD-07 — Introduce a thin domain layer for tracking & IAP

| | |
|--|--|
| **Severity** | High |
| **Description** | No ViewModels/services; logic embedded in large SwiftUI files. |
| **Why it matters** | Hard to test and reuse; bugs like TD-01/02 recur easily. |
| **Suggested solution** | Extract `SkillTrackingService`, `StatsCalculator`, `EntitlementsStore`; keep views declarative. |

---

## Medium

### TD-08 — Deduplicate distribution / PDF histogram code

| | |
|--|--|
| **Severity** | Medium |
| **Description** | Bin edges and stats math copied 3×. |
| **Why it matters** | Fixes must be applied in multiple places. |
| **Suggested solution** | Shared `TimeDistributionCalculator` used by UI + PDF. |

### TD-09 — Deduplicate verification code generation & remove debug prints

| | |
|--|--|
| **Severity** | Medium |
| **Description** | Multiple generators; dead methods; verbose `print`. |
| **Why it matters** | Noise, dead code, possible info leakage in device logs. |
| **Suggested solution** | One utility; delete unused methods; use `Logger` with levels. |

### TD-10 — Improve localization completeness

| | |
|--|--|
| **Severity** | Medium |
| **Description** | Hard-coded English in Start/Stop and `RecentTrackingView`; seeder uses 2-letter language only. |
| **Why it matters** | Breaks 40-language promise for key flows. |
| **Suggested solution** | Localize remaining strings; resolve catalog/quotes with full locale identifiers + fallback chain. |

### TD-11 — Persist custom skill images safely

| | |
|--|--|
| **Severity** | Medium |
| **Description** | Custom skills may store filesystem paths that do not survive reinstall/container changes. |
| **Why it matters** | Broken images for Pro users. |
| **Suggested solution** | Copy into Application Support with relative keys, or store in SwiftData/FileManager app sandbox with stable IDs. |

### TD-12 — Surface IAP and persistence errors in UI

| | |
|--|--|
| **Severity** | Medium |
| **Description** | Empty catches / `try?` hide failures. |
| **Why it matters** | Users cannot restore purchases or diagnose save issues. |
| **Suggested solution** | Publish `errorMessage` from `IAPManager`; alert on save failures. |

### TD-13 — Commit shared scheme, entitlements visibility, StoreKit config

| | |
|--|--|
| **Severity** | Medium |
| **Description** | Repo lacks shared `.xcscheme`, entitlements file, `.storekit`. |
| **Why it matters** | Slow onboarding; fragile CI; hard IAP testing. |
| **Suggested solution** | Add shared scheme; check in StoreKit config for sandbox; document capabilities. |

### TD-14 — Stop mutating catalogs during every versioned build without review

| | |
|--|--|
| **Severity** | Medium |
| **Description** | Run Script rewrites JSON in the working tree. |
| **Why it matters** | Surprise git diffs; merge conflicts. |
| **Suggested solution** | Bump catalog versions in a deliberate release PR, or write derived version to build products only. |

### TD-15 — Record signed duration for manual adjustments

| | |
|--|--|
| **Severity** | Medium |
| **Description** | Negative adjustments store absolute minutes. |
| **Why it matters** | Distorts histograms. |
| **Suggested solution** | Store signed minutes or separate adjustment events excluded from duration histograms. |

---

## Low

### TD-16 — Remove or wire dead UI

| | |
|--|--|
| **Severity** | Low |
| **Description** | `SupportDeveloperView`, `DevPaywallView`, unused buttons/backgrounds, unused state vars. |
| **Why it matters** | Maintenance noise; confusion about product surface. |
| **Suggested solution** | Delete or link from About/Options; prune unused design-system variants. |

### TD-17 — Consolidate privacy markdown files

| | |
|--|--|
| **Severity** | Low |
| **Description** | `PRIVACY.md` vs `PrivacyPolicy.md`. |
| **Why it matters** | Editors update the wrong file. |
| **Suggested solution** | Keep one; make the other a stub link. |

### TD-18 — Clean file headers / typos

| | |
|--|--|
| **Severity** | Low |
| **Description** | Duplicate `MainView` header; `StatsView` `//  .` comment. |
| **Why it matters** | Polish / professionalism. |
| **Suggested solution** | Trivial cleanup pass. |

### TD-19 — Replace force unwraps with guards

| | |
|--|--|
| **Severity** | Low |
| **Description** | Calendar/URL/`randomElement` force unwraps. |
| **Why it matters** | Defensive Swift style; rare crash vectors. |
| **Suggested solution** | `guard let` / static URL constants. |

### TD-20 — Expand test matrix beyond Skill colors

| | |
|--|--|
| **Severity** | Low |
| **Description** | No tests for seeder upsert, IAP mapping, interval aggregation, daily limit. |
| **Why it matters** | Core business rules unprotected. |
| **Suggested solution** | Add focused unit tests with in-memory ModelContainer. |

### TD-21 — Consider lowering deployment target (product decision)

| | |
|--|--|
| **Severity** | Low |
| **Description** | iOS 18.2-only excludes many devices. |
| **Why it matters** | Addressable market. |
| **Suggested solution** | Decide intentionally; if supporting older OS, audit API availability. |

---

## Suggested improvement order (executive)

1. **TD-01** (Pro unlock)  
2. **TD-02** + **TD-03** (stats data integrity)  
3. **TD-04** (tests)  
4. **TD-06** + **TD-07** (architecture foundations)  
5. Dedup / localization / dead code (**TD-08…TD-16**)
