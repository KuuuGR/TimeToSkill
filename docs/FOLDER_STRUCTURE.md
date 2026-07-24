# Folder Structure — TimeToSkill

Repository layout (major folders only):

```text
TimeToSkill/                          # Git repository root
├── README.md, FAQ.md, TERMS.md, …
├── PRIVACY.md, PrivacyPolicy.md      # Duplicate-ish privacy docs
├── ReleaseNotes
├── scripts/
│   └── bump_catalog_version.py
├── docs/                             # This documentation set
└── TimeToSkill/                      # Xcode project wrapper
    ├── TimeToSkill.xcodeproj/
    └── TimeToSkill/                  # App sources + resources + tests
        ├── Sources/
        ├── Resources/
        └── Tests/
```

---

## `/` (repository root)

**Purpose:** Product metadata, legal/support copy, automation scripts, documentation.

**Important files:**

| File | Role |
|------|------|
| `README.md` | Marketing overview + feature list |
| `FAQ.md` | End-user FAQ |
| `ReleaseNotes` | Changelog (YAML-ish front matter + bullets) |
| `LICENSE.md`, `TERMS.md`, `SUPPORT.md` | Legal / support |
| `PRIVACY.md`, `PrivacyPolicy.md` | Privacy statements (overlapping content) |
| `scripts/bump_catalog_version.py` | Build-phase catalog version bump |
| `docs/` | Engineering documentation (this folder) |

**Relationships:** Root docs describe product intent; implementation lives under `TimeToSkill/TimeToSkill/`.

---

## `scripts/`

**Purpose:** Build/tooling scripts invoked outside or during Xcode builds.

**Important files:**

- `bump_catalog_version.py` — when `MARKETING_VERSION` increases, increments `catalogVersion` in all `ExemplarySkills*.json` under Resources.

**Relationships:** Referenced by Xcode Run Script phase in `project.pbxproj`. Path resolution uses `PROJECT_DIR` heuristics.

---

## `TimeToSkill/` (Xcode wrapper)

**Purpose:** Contains the `.xcodeproj` and the synchronized app folder.

### `TimeToSkill.xcodeproj/`

**Purpose:** Xcode project definition (objectVersion 77, file-system synchronized groups).

**Important contents:**

- `project.pbxproj` — targets, build settings, run script, signing team
- `xcuserdata/` — per-user scheme management (not shared schemes checked in)
- `project.xcworkspace/` — default workspace container

**Relationships:** Builds the app from `TimeToSkill/TimeToSkill/` via `PBXFileSystemSynchronizedRootGroup`.

---

## `TimeToSkill/TimeToSkill/Sources/`

**Purpose:** All application Swift code.

### `Sources/TimeToSkillApp.swift`

App entry: SwiftData container, dark mode, IAP environment object, root `SplashView`.

### `Sources/Models/`

**Purpose:** SwiftData / Codable domain types.

| File | Notes |
|------|-------|
| `Skill.swift` | Core tracker model |
| `TimeIntervalEntry.swift` | Interval log + source enum |
| `Counter.swift` | Counters + threshold encoding |
| `ExemplarySkill.swift` | Achievements + `AchievementRecord` + constants |
| `Quote.swift` | Non-persisted quote DTO |

**Relationships:** Queried/mutated by Views; seeded from Resources JSON.

### `Sources/Views/`

**Purpose:** Screens and feature UI (primary app layer).

| Subfolder / area | Purpose |
|------------------|---------|
| Root view files | Splash, Main, Start, Options, Stats, Theory, About, Exemplary, Counters, Support |
| `Components/` | Reusable feature widgets (progress, paywall, cards, sheets) |
| `Components/Stats/` | Stats section widgets |
| `Stats/` | Global distribution chart view |
| `Shared/` | Cross-cutting helpers (`IAPManager`, `SkillSeeder`, `ShareSheet`) |

**Relationships:** Depends on Models + DesignSystem; owns most business logic.

### `Sources/DesignSystem/`

**Purpose:** Visual language primitives.

| Path | Purpose |
|------|---------|
| `AppColors.swift` | Brand / semantic colors |
| `Typography/AppTypography.swift` | Font tokens |
| `Component/Button/` | FAB, Fancy style, Primary/Secondary |
| `Animation/` | Background variants + `AppBackground` facade |

**Relationships:** Used by Views; several animation/button components are currently unused by screens.

---

## `TimeToSkill/TimeToSkill/Resources/`

**Purpose:** Bundled assets and localized content.

| Path | Purpose |
|------|---------|
| `Assets.xcassets/` | App icon, accent, `app_logo` |
| `Localization/*.lproj/Localizable.strings` | ~40 UI localizations |
| `Quotes/*_quotes.json` | Motivational quotes per locale |
| `ExemplarySkills.json` + `ExemplarySkills_*.json` | Achievement catalogs (~40) |

**Relationships:** Loaded by `QuoteLoader`, `SkillSeeder`, and SwiftUI `LocalizedStringKey` / `NSLocalizedString`. Catalog versions may be mutated by build script.

---

## `TimeToSkill/TimeToSkill/Tests/`

**Purpose:** Test targets’ source (also synchronized into the Xcode folder tree with membership exceptions).

| Path | Purpose |
|------|---------|
| `TimeToSkillTests/SkillTests.swift` | Sparse unit tests |
| `TimeToSkillUITests/StartViewUITests.swift` | UI navigation smoke test |
| `TimeToSkillUITests/TimeToSkillUITestsLaunchTests.swift` | Launch + theory nav + screenshot |

**Relationships:** Depend on app target; UITests launch the app binary.

---

## `.vscode/`

**Purpose:** Editor settings for VS Code/Cursor (`settings.json`).

**Relationships:** Does not affect Xcode builds.

---

## Notable structural observations

1. **Tests live inside the app synchronized folder** with membership exceptions — convenient but unusual vs classic sibling `TimeToSkillTests/` at project root.
2. **`Shared/` sits under `Views/`** even though `IAPManager` / `SkillSeeder` are not views.
3. **No `ViewModels/`, `Services/`, `Networking/`, or `Utilities/` packages** — logic is colocated with UI.
4. **Duplicate privacy docs** at repo root (`PRIVACY.md` vs `PrivacyPolicy.md`).
