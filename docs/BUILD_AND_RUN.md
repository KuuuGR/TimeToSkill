# Build and Run — TimeToSkill

## Prerequisites

1. **macOS** with **Xcode 16.2+** (project created on 16.2; deployment **iOS 18.2**).
2. Apple Developer account that can sign for team **`8TC5J5KMXE`** (or change the team locally).
3. **Python 3** on `PATH` (`/usr/bin/env python3`) for the catalog version Run Script (script fails soft if missing path, but phase uses `set -e` around setup).
4. Optional: App Store Connect product `com.gregkaps.timetoskill.pro` configured for IAP testing.

---

## How to open and run

1. Open `TimeToSkill/TimeToSkill.xcodeproj` in Xcode.
2. Select the **TimeToSkill** scheme/target.
3. Pick an **iOS 18.2+** simulator or device.
4. Build & Run (⌘R).

Expected launch path: on the 1st, 32nd, 64th and 128th launch the animated splash plays for ~12s before `MainView`; every other launch goes straight to `MainView`. On the 16th and 256th launch a native App Store rating prompt is requested once the main UI settles.

---

## Targets

| Target | Type | Bundle ID |
|--------|------|-----------|
| `TimeToSkill` | Application | `gregkaps.TimeToSkill` |
| `TimeToSkillTests` | Unit tests | `gregkaps.TimeToSkillTests` |
| `TimeToSkillUITests` | UI tests | `gregkaps.TimeToSkillUITests` |

---

## Schemes

- User scheme management plists reference `TimeToSkill.xcscheme_^#shared#^_`.
- **No shared `.xcscheme` file is committed** under `xcshareddata/xcschemes/`.
- Xcode will usually auto-generate a scheme from the app target; CI/other machines may need the scheme recreated or shared schemes added.

---

## Build configurations

| Configuration | Notes |
|---------------|-------|
| **Debug** | Development; `MARKETING_VERSION = 1.4`, `CURRENT_PROJECT_VERSION = 5` on app |
| **Release** | Same marketing/build numbers on app target |

Test targets still declare marketing version `1.0` / build `1` (cosmetic for tests).

---

## Signing

| Setting | Value |
|---------|-------|
| `CODE_SIGN_STYLE` | Automatic |
| `DEVELOPMENT_TEAM` | `8TC5J5KMXE` |
| Entitlements file | **Not present** in repo |

**Assumption:** Capabilities (In-App Purchase) are managed in the Apple Developer portal / Xcode Signing & Capabilities UI rather than a checked-in `.entitlements` file. Confirm IAP capability is enabled before shipping purchases.

---

## Info.plist / generated keys

`GENERATE_INFOPLIST_FILE = YES` — no checked-in `Info.plist`.

Notable generated keys:

- Category: Productivity
- Scene manifest generation enabled
- Launch screen generation enabled
- Orientations: iPhone portrait + landscapes; iPad all listed orientations

App forces dark appearance in code regardless of system light mode.

---

## Environment variables

No app runtime `.env` or xcconfig secrets.

Build-phase / script-related env:

| Variable | Source | Purpose |
|----------|--------|---------|
| `MARKETING_VERSION` | Xcode build setting | Catalog bump trigger |
| `CATALOG_VERSION_STRATEGY` | Set to `bump` in Run Script | How JSON `catalogVersion` updates |
| `PROJECT_DIR` | Xcode | Locate Resources / script |

---

## Configuration files

| File | Present? |
|------|----------|
| `*.xcconfig` | No |
| `Info.plist` | Generated |
| `*.entitlements` | No |
| `*.storekit` | No |
| CocoaPods / SPM lockfiles | No |

---

## Run Script phase

**Name:** `Run Script: Bump catalogVersion on app version change`

- Runs `scripts/bump_catalog_version.py` when marketing version increases vs `.last_marketing_version` state file under Resources.
- Mutates ExemplarySkills JSON in the source tree during build — be aware this can dirty the working copy.

---

## Missing assets / secrets

| Item | Status | Impact |
|------|--------|--------|
| Shared Xcode scheme | Missing from git | Friction for CI/clones |
| StoreKit Configuration file | Missing | Harder local IAP sandbox without App Store Connect |
| Entitlements file | Missing | Capability state not visible in repo |
| API keys / backend secrets | N/A (offline app) | — |
| `app_logo` / AppIcon | Present in Assets | Required for splash |

---

## Running tests

In Xcode: Product → Test (⌘U), or run individual test targets.

**Caveats (see KNOWN_ISSUES):**

- Unit tests for progress colors appear outdated vs current color tokens.
- UITests look for English strings like `"Start Tracking"` / `"Learning Theory"` and may fail against current localization keys (`Manage Trackers`, splash delay, etc.).

---

## Suggested first-run checklist

1. Team signing resolves without errors.
2. App launches past splash on simulator.
3. Create a skill, start/stop timer, confirm hours increase.
4. Open Exemplary Skills — catalog seeds on appear.
5. Open paywall — product loads only if StoreKit product is available for the signed account/sandbox.
