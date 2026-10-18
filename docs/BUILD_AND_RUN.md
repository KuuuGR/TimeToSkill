# Build and Run — Time4Skill

This branch (`Time4Skill-MacOS`) builds **Time4Skill**. The Xcode project remains `TimeToSkill/TimeToSkill.xcodeproj` inside the TimeToSkill repository. The shipping TimeToSkill app stays on `release/ver1.6` with bundle ID `gregkaps.TimeToSkill`; that identifier is not the iOS target on this branch.

App Store Connect has one Time4Skill record (Apple ID `6816741946`, SKU `com.etaosin.time4skill-2026`) with separate iOS and macOS platforms. Both platforms use bundle ID `com.etaosin.time4skill`.

## Prerequisites

1. **macOS** with **Xcode 16.2+** (project created on 16.2; iOS deployment **18.2**, macOS deployment **15.0**).
2. Apple Developer account that can sign for team **`8TC5J5KMXE`** (or change the team locally).
3. **Python 3** on `PATH` (`/usr/bin/env python3`) for the catalog version Run Script (script fails soft if missing path, but phase uses `set -e` around setup).

This branch does not ship the old TimeToSkill in-app purchase (`com.gregkaps.timetoskill.pro`).

---

## How to open and run

1. Open `TimeToSkill/TimeToSkill.xcodeproj` in Xcode.
2. Select the **Time4Skill** scheme for iOS, or **Time4SkillMacOS** for Mac.
3. For iOS, pick an **iOS 18.2+** simulator or device. For Mac, choose **My Mac**.
4. Build & Run (⌘R).

Expected launch path: on the 1st, 32nd, 64th and 128th launch the animated splash plays for ~12s before `MainView`; every other launch goes straight to `MainView`. On the 16th and 256th launch a native App Store rating prompt is requested once the main UI settles.

---

## Targets

| Target | Type | Bundle ID | Version | Build |
|--------|------|-----------|---------|-------|
| `Time4Skill` | iOS application | `com.etaosin.time4skill` | 1.6 | 17 |
| `Time4SkillTests` | iOS unit tests | `gregkaps.Time4SkillTests` | 1.0 | 1 |
| `Time4SkillUITests` | iOS UI tests | `gregkaps.Time4SkillUITests` | 1.0 | 1 |
| `Time4SkillMacOS` | macOS application | `com.etaosin.time4skill` | 1.6 | 16 |

Debug and Release use the same bundle ID, marketing version, and build number on each application target. The historical TimeToSkill release (`gregkaps.TimeToSkill`) is not a target in this working tree.

---

## Schemes

Shared schemes live at `TimeToSkill/TimeToSkill.xcodeproj/xcshareddata/xcschemes/` and are currently **untracked**:

| Scheme | Builds / archives | Archive configuration |
|--------|-------------------|------------------------|
| `Time4Skill.xcscheme` | iOS target `Time4Skill` (`Time4Skill.app`) | Release |
| `Time4SkillMacOS.xcscheme` | macOS target `Time4SkillMacOS` (`Time4SkillMacOS.app`) | Release |

The iOS scheme launches Debug. The macOS scheme launches Release. Both archive Release. A clone of committed HEAD does not contain these scheme files until they are added to git.

---

## Build configurations

| Target | Debug and Release |
|--------|-------------------|
| `Time4Skill` | `MARKETING_VERSION = 1.6`, `CURRENT_PROJECT_VERSION = 17` |
| `Time4SkillMacOS` | `MARKETING_VERSION = 1.6`, `CURRENT_PROJECT_VERSION = 16` |

Test targets still declare marketing version `1.0` / build `1` (cosmetic for tests).

Before the next App Store upload, set each platform's build higher than the build already uploaded for the rejected 1.6 version. The uploaded build numbers are not stored in this repository, so these numbers were left unchanged.

---

## Signing

| Setting | Value |
|---------|-------|
| `CODE_SIGN_STYLE` | Automatic |
| `DEVELOPMENT_TEAM` | `8TC5J5KMXE` |
| Entitlements file | `TimeToSkill/Time4SkillMacOS.entitlements` — macOS target only (`CODE_SIGN_ENTITLEMENTS` in Debug **and** Release) |

`Time4SkillMacOS.entitlements` contains only `com.apple.security.app-sandbox = true`, which the Mac App Store requires (App Store Connect rejects archives without it — validation error 90296). The file sits next to `TimeToSkill.xcodeproj`, outside the file-system synchronized `TimeToSkill/TimeToSkill` folder, so it is not copied into any bundle. The iOS target has no entitlements file and does not need one.

The sandbox entitlement file is in the working tree and referenced by the macOS target. It is not committed on HEAD. This branch has no in-app purchase capability in the project.

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
| `*.entitlements` | Yes — `Time4SkillMacOS.entitlements` (macOS target, App Sandbox) |
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
| Shared Xcode schemes | Present locally, untracked | A fresh clone of HEAD has no `Time4Skill` / `Time4SkillMacOS` schemes |
| StoreKit Configuration file | Missing | Harder local IAP sandbox without App Store Connect |
| Entitlements file (macOS) | Present | `Time4SkillMacOS.entitlements` — App Sandbox for the Mac App Store build |
| Entitlements file (iOS) | Missing | None required today; add one if iOS capabilities are ever needed |
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
5. Export a PDF from Options and confirm the shared file name starts with `Time4Skill-Export-`.
