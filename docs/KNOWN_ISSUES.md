# Known Issues — TimeToSkill

Audit performed by static inspection only. **Nothing was fixed.** Compiler warnings were not captured from a live Xcode build (no build log in this pass); items below are code-smell / correctness findings.

---

## Critical correctness

### 1. Pro unlock never sets `customSkillUnlocked`

- UI gates custom skills / daily-limit reset on `@AppStorage("customSkillUnlocked")`.
- `IAPManager` sets `isPurchased = true` after StoreKit verification.
- **No write** of `customSkillUnlocked = true` exists anywhere in the Swift sources.
- **Effect:** Successful purchase can dismiss the paywall but leave Pro features locked.

### 2. `Skill.lastUpdated` never updates after creation

- Set only in `Skill.init`.
- Timer stop / manual adjust / rename do not touch it.
- **Effect:** `TrackedTimeView` week/month filters, `ActivityLogView`, `RecentTrackingView`, and `StatsSummaryView` earliest-date logic are wrong or useless.

### 3. Skill delete does not remove related `TimeIntervalEntry` rows

- Entries reference `skillId` UUID without SwiftData relationship/cascade.
- **Effect:** Orphan intervals inflate global distribution / PDF histograms.

---

## High severity

### 4. Unit tests likely failing / stale

`SkillTests` expects progress colors like `.green.opacity(0.7)` / `.orange.opacity(0.7)` / `.red.opacity(0.7)`, but `SkillProgressView` uses `.success`, `.infoDark`, `.warningDark`, etc.

### 5. UITests out of sync with UI copy

- `StartViewUITests` taps `"Start Tracking"`; English strings use `"Manage Trackers"` (`main_manage_trackers`).
- Launch tests assume English `"Learning Theory"` and may race splash timing.
- Large timer UITest is commented out.

### 6. Privacy messaging inconsistent with IAP

- `PRIVACY.md` / FAQ claim fully offline / no internet.
- App uses StoreKit and paywall links to GitHub wiki.
- `PrivacyPolicy.md` is more accurate (mentions App Store purchase).

### 7. Nested `NavigationStack`s

Multiple presented screens create their own stacks inside `MainView`’s stack/sheets. Risk of broken back navigation, double bars, and poor deep-link readiness.

### 8. Splash retained under `fullScreenCover` — **fixed**

`RootView` now owns the splash/main switch in one root `Group` and removes `SplashView` from the hierarchy once the choreography ends, so nothing stays alive underneath. The splash also only runs on the 1st, 32nd, 64th and 128th launch (`AppLaunch`); other launches go straight to `MainView`.

---

## Medium severity

### 9. Force unwraps

| Location | Expression | Risk |
|----------|------------|------|
| `OptionsView` | `oldValue!` | Mitigated by nil checks, still brittle |
| `PaywallView` | `URL(string: "https://…")!` | Safe for literals; style smell |
| `TrackedTimeView` / `RecentTrackingView` | `Calendar…date(byAdding:)!` | Practically safe for day offsets |
| Verification code generators | `randomElement()!` | Safe while charset non-empty |
| `FABButton` / `CustomExemplarySkillSheet` | `accessibilityLabelKey!` / `finalCategoryKey!` | Guarded by nil checks |

No `try!` / `as!` / `fatalError` found in app sources.

### 10. Silent error handling

Widespread `try?` on SwiftData saves and empty `catch` in IAP. Failures leave UI without feedback.

### 11. Stats week/month logic uses total skill hours, not interval sums

Even if `lastUpdated` worked, filtering skills by lastUpdated then summing **lifetime** `hours` is not “hours tracked this week.”

### 12. Duplicate histogram / binning logic

Nearly identical stats math and bar drawing in:

- `GlobalTimeDistributionView`
- `OptionsView` PDF helpers

`TimeDistributionView` no longer duplicates the old binning: it filters with `@Query`, uses fixed bucket edges `[0, 5, 10, 15, 30, 60, 120, 240, 480, 960]` plus a trailing `≥ 960m` bucket, and draws a horizontal bar chart. On macOS the chart is laid out at its natural height instead of inside a `ScrollView`, because a macOS sheet sizes itself to its content: with a scroll view the options window collapsed to a thin strip around the title bar when the screen was pushed. The sheet now grows until the last bucket is visible, keeping the same inset above the skill name and below the histogram; iOS keeps the scroll view for short devices. The two remaining spots still carry the old `[0 … 960, maxVal + 1]` edges.

### 13. Duplicate verification-code generators

`generateVerificationCode()` appears in:

- `ExemplarySkillsView` (unused)
- `ExemplarySkillDetailView`
- `StarRating` (unused dead method)
- `VerificationView`

Debug `print` statements left in verification flow.

### 14. `Quote.id` regenerates every access

```swift
var id: UUID { UUID() }
```

Breaks stable `Identifiable` identity if used in lists/animations.

### 15. Localization / hard-coded English

Examples:

- `SkillProgressView` Start/Stop button titles are hard-coded English.
- `RecentTrackingView` titles `"⏳ Recent Tracking"`, `"This Week"`, `"This Month"` hard-coded (and view appears unused by `StatsView`).
- Some star labels mix localized and raw `"Stars"` / `"Star"`.

### 16. Seeder language matching is coarse

Uses first two letters of preferred language (`pl`, `en`) — may miss region-specific catalogs (`en-AU`, `pt-BR`, `zh-Hans`) even when those JSON files exist.

### 17. Build script mutates source JSON

Catalog bump Run Script can dirty git on version bumps — surprising for CI/local builds.

### 18. No shared scheme / entitlements / StoreKit config in repo

See `BUILD_AND_RUN.md` — onboarding and IAP local testing friction.

---

## Low severity / code smells

### 19. Dead / unused types & views

| Item | Notes |
|------|-------|
| `SupportDeveloperView` | Never navigated to |
| `DevPaywallView` | Never referenced |
| `PrimaryButton` / `SecondaryButton` | Only self-previews |
| `RecentTrackingView` | Not used in `StatsView` |
| Unused animation modes | `MainView` hardcodes `.staticCircle`; pulse/gradient/circle variants idle |
| `MainView.showStats` | Declared unused (actual flag is `showingStats`) |
| `MainView.animateFAB` | Set but FAB pulse uses `hasSeenFABAnimation` path instead |
| `import Combine` in `OptionsView` | Apparently unused |
| `import PDFKit` | PDF via UIKit renderer |
| `StarRating.generateVerificationCode` | Dead method on wrong type |
| `ExemplarySkillsView.generateVerificationCode` | Unused |

### 20. Large view files (logic + UI)

| File | ~LOC |
|------|------|
| `ExemplarySkillDetailView.swift` | 502 |
| `OptionsView.swift` | 463 |
| `ExemplarySkillsView.swift` | 328 |
| `ManageCountersView.swift` | 215 (multiple types) |
| `MainView.swift` | 212 |

No dedicated ViewModels; complexity concentrated in views.

### 21. Duplicate file header in `MainView.swift`

Header comment block repeated twice.

### 22. Empty/broken file comment in `StatsView.swift`

`//  .` placeholder header.

### 23. Debug logging in production paths

`print` in seeder, quote loader, verification, detail sheets.

### 24. XCTest framework embed on test targets

Test targets embed `XCTest.framework` — unusual but not on the app target (app Embed Frameworks is empty). Worth confirming this is intentional for the Xcode version used.

### 25. Manual time adjust records absolute minutes only

Negative adjustments still store `abs(totalHours) * 60` as positive `TimeIntervalEntry`, skewing distributions.

### 26. Timer accuracy / lifecycle

No background handling for `activeStart` if app is killed mid-timer (hours not credited until stop). Not necessarily a bug, but product gap.

---

## TODOs / FIXMEs

**None found** (`TODO`, `FIXME`, `HACK`, `XXX` search empty).

---

## Threading / memory (potential)

| Topic | Observation |
|-------|-------------|
| IAP | `@MainActor` manager; `Task { [weak self] in … }` — good |
| `observeTransactions` | Infinite `for await` loop started from init — expected StoreKit pattern; ensure only one observer (singleton helps) |
| `DispatchQueue.main.asyncAfter` | Splash, FAB, success toast — retain views until fire; generally fine |
| SwiftUI performance | Sorting large `@Query` arrays in computed properties on every body pass (`StartView.sortedSkills`, exemplary sorts) — OK for small N, costly if catalogs grow |
| Image loading | File-path `UIImage(contentsOfFile:)` for custom skills — ensure paths remain valid across reinstalls (they often do not) |

No classic retain-cycle smoking gun beyond splash cover retention and long-lived singleton.

---

## SwiftUI anti-patterns observed

1. Business logic inside views.
2. Nested navigation stacks.
3. Root presented via `fullScreenCover` instead of swapping root state.
4. Heavy `onAppear` side effects (seeding, quote load, distribution fetch) without refresh strategy.
5. Force dark via both `.preferredColorScheme` and environment override.
6. Using `@AppStorage` as monetization source of truth separate from StoreKit entitlements.
