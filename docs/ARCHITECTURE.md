# Architecture — TimeToSkill

## Summary answer: which architecture is used?

**Pragmatic SwiftUI + SwiftData, view-centric (not MVVM / not Clean Architecture).**

There are **no ViewModels**, no repositories, no use-case layer, and almost no dependency injection. Views own `@Query` / `@Environment(\.modelContext)`, call managers/helpers directly, and embed business logic in private methods.

Closest labels:

| Aspect | Pattern in this codebase |
|--------|---------------------------|
| UI | SwiftUI views (composition) |
| Persistence | SwiftData `@Model` + `@Query` |
| Shared app state | Singleton `IAPManager` + `@AppStorage` / `UserDefaults` |
| Structure | Feature screens under `Views/`, light `Models/`, thin `DesignSystem/` |

---

## High-level diagram

```text
┌─────────────────────────────────────────────────────────┐
│ TimeToSkillApp (@main)                                  │
│  • modelContainer(Skill, ExemplarySkill, Counter, …)    │
│  • @StateObject IAPManager.shared → environmentObject   │
│  • preferredColorScheme(.dark)                          │
└──────────────────────────┬──────────────────────────────┘
                           │
                     SplashView
                           │ fullScreenCover
                     MainView (NavigationStack)
           ┌───────────────┼────────────────┐
           │               │                │
     Nav destinations   FAB sheets     local @State
     (Start, Counters,  (Stats, Options, Paywall,
      Theory, Exemplary, Custom skill)
      About)
           │
           ▼
   SwiftData ModelContext / @Query
           │
   ┌───────┴────────┬──────────────┬────────────────┐
   Skill            Counter        ExemplarySkill   TimeIntervalEntry
```

---

## Navigation

- **Primary:** `NavigationStack` in `MainView` + `NavigationLink` to feature screens.
- **Modal:** `.sheet` for Options, Stats, Paywall, Add Skill, Skill Options, Custom Skill, Exemplary detail.
- **Launch:** `SplashView` presents `MainView` via `.fullScreenCover` after delay (splash remains under the cover).
- **Nested stacks:** Several child screens (`ExemplarySkillsView`, `ManageCountersView`, `OptionsView`, `StatsView`, sheets) create **additional** `NavigationStack`s. Works for small apps; harder to scale (deep links, coordinated paths, single source of truth).

There is **no** `NavigationPath`, coordinator, or router.

---

## State management

| Mechanism | Used for |
|-----------|----------|
| `@State` / `@Binding` / `@FocusState` | Local UI |
| `@Query` | Live SwiftData collections |
| `@Bindable` | Mutating SwiftData models in forms |
| `@AppStorage` | Sort prefs, FAB seen flag, `customSkillUnlocked`, exemplary sort |
| `UserDefaults` | Daily evaluation count/date, last seeded catalog version |
| `@EnvironmentObject` / `@StateObject` | `IAPManager` only |
| `@Published` | IAP product + purchased flag |

No unidirectional data flow, no reducers, no Observable ViewModels (`@Observable` unused).

---

## Dependency injection

**Minimal / ad hoc.**

- SwiftData container injected by `.modelContainer(...)` on the `WindowGroup`.
- IAP via singleton `IAPManager.shared` also held as `@StateObject` and passed as `environmentObject`.
- Helpers are static enums/classes (`SkillSeeder`, `QuoteLoader`) with no protocol abstractions.

---

## Networking & API communication

**None for app data.** No `URLSession`, no REST/GraphQL client, no sync API.

Network-related behavior:

- StoreKit talks to the App Store.
- Optional outbound links (PayPal in unused `SupportDeveloperView`, privacy/terms URLs on paywall).

---

## Persistence

### SwiftData (primary)

Models registered in `TimeToSkillApp`:

1. `Skill`
2. `ExemplarySkill` (+ embedded `AchievementRecord` Codable array)
3. `Counter` (thresholds stored as encoded `Data`)
4. `TimeIntervalEntry`

Relationships:

- `TimeIntervalEntry.skillId` is a **loose UUID**, not a SwiftData `@Relationship`. Orphan entries possible after skill delete.
- No cascade delete rules defined in code.

### UserDefaults / AppStorage

Preferences and soft feature flags (unlock, sorts, daily limits, seed version).

### Bundle JSON (read-only assets)

- `Resources/Quotes/*_quotes.json`
- `Resources/ExemplarySkills*.json` (versioned catalog)

Build-phase Python script can bump `catalogVersion` when marketing version increases.

---

## Authentication

**None.** Offline-first, no accounts, no Sign in with Apple.

“Verification” in Exemplary Skills is a **local attention gate** (type a generated code), not security/auth.

---

## Models

| Model | Role |
|-------|------|
| `Skill` | Named tracker + hours + optional active timer start |
| `TimeIntervalEntry` | Session/manual intervals for histograms |
| `Counter` | Tap counter with thresholds |
| `ExemplarySkill` | Catalog/user achievement + rating history |
| `Quote` | Decodable quote (not persisted) |
| `SeedSkill` / `SkillCatalog` | JSON seed DTOs (not SwiftData) |
| `AchievementRecord` | Codable history row inside exemplary skill |

---

## Services / managers / utilities

| Type | Location | Role |
|------|----------|------|
| `IAPManager` | `Views/Shared/` | StoreKit 2 purchases & entitlements |
| `SkillSeeder` | `Views/Shared/` | Upsert exemplary catalog |
| `QuoteLoader` | `Views/Components/` | Load localized quotes |
| `ShareSheet` | `Views/Shared/` | `UIActivityViewController` bridge |
| PDF helpers | inside `OptionsView` | Generate report |

There is **no** dedicated `Services/` or `Managers/` package layer. Naming/placement is inconsistent (`IAPManager` under Views).

---

## ViewModels

**Absent.** Logic lives in views (notably `OptionsView`, `ExemplarySkillsView`, `ExemplarySkillDetailView`, `StartView`).

---

## Design system

Under `Sources/DesignSystem/`:

- `AppColors` / `Color` hex helpers
- `AppTypography` (system fonts)
- Buttons: `FABButton`, `FancyButtonStyle`, unused `PrimaryButton` / `SecondaryButton`
- Background animations: `AppBackground` + several animation types (only `.staticCircle` used from `MainView`)

---

## Testing architecture

- Unit target: `TimeToSkillTests` (`SkillTests.swift`) — very few assertions; color expectations appear stale vs current `AppColors`.
- UI target: `TimeToSkillUITests` — brittle English string / accessibility assumptions; one test still looks for `"Start Tracking"` while UI uses localized `"Manage Trackers"`.

No UI test page objects, no SwiftData in-memory fixtures shared across tests.

---

## Scalability notes

**Strengths for current size (~5k LOC Swift):** simple mental model, fast feature addition in one file.

**Limits as the app grows:**

- Business rules scattered in views → hard to reuse/test.
- Nested navigation stacks → deep linking / state restoration painful.
- IAP flag split (`isPurchased` vs `customSkillUnlocked`) → fragile monetization.
- Duplicated histogram/binning logic across Options PDF + distribution views.
- Loose UUID linking for intervals → integrity risk.
