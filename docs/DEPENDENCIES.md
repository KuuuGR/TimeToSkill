# Dependencies — TimeToSkill

## Language & tooling

| Item | Value | Why |
|------|-------|-----|
| Swift | **5.0** (`SWIFT_VERSION = 5.0`) | Project language |
| Xcode | Created with **16.2**; `LastUpgradeCheck = 1630` | Toolchain that matches iOS 18 / modern project format |
| Project format | `objectVersion = 77` + file-system synchronized groups | Modern Xcode folder sync |
| Deployment target | **iOS 18.2** | Uses recent SwiftUI/SwiftData/StoreKit APIs |
| Platforms | iPhone + iPad (`TARGETED_DEVICE_FAMILY = 1,2`) | Universal iOS app |
| Python 3 | Required for catalog bump script | Run Script build phase |

**Assumption:** Building requires Xcode 16.x (or newer that still supports objectVersion 77 / iOS 18.2 SDK). Not verified against older Xcode.

---

## UI frameworks

| Framework | Usage | Why |
|-----------|-------|-----|
| **SwiftUI** | Primary UI for all screens | Modern declarative UI |
| **UIKit** | PDF drawing (`UIGraphicsPDFRenderer`), `UIActivityViewController` (`ShareSheet`), haptics, `UIImage` loading, `UIScreen`, `UIApplication.open` | Bridging for share/PDF/images/system APIs SwiftUI does not fully cover |
| **PDFKit** | Imported in `OptionsView` | Declared; PDF generation currently uses UIKit graphics APIs |

---

## Apple frameworks (first-party)

| Framework | Where | Why |
|-----------|-------|-----|
| **SwiftData** | Models + `@Query` + `modelContainer` | Local persistence |
| **Foundation** | Models, loaders, dates, JSON | Core types |
| **StoreKit** (StoreKit 2) | `IAPManager` | Lifetime Pro IAP |
| **Combine** | Imported in `OptionsView` | **Likely unused** import (no Combine APIs spotted) |
| **XCTest** | Unit + UI test targets | Testing |

No CloudKit, Core Data (legacy), WidgetKit, HealthKit, etc.

---

## Swift Package Manager (SPM)

**None.**

`packageProductDependencies` is empty on all targets. No `Package.swift`, no `Package.resolved`.

---

## CocoaPods / Carthage

**None.** No `Podfile`, `Podfile.lock`, or Carthage files.

---

## Third-party libraries

**None linked.** The app is Apple-frameworks-only.

---

## Bundled content dependencies (not code packages)

| Asset set | Count (approx.) | Why |
|-----------|-----------------|-----|
| `Localizable.strings` locales | ~40 | Multilingual UI |
| Quote JSON files | ~46 | Localized motivation quotes |
| Exemplary skill catalogs | ~40 | Localized achievement catalog |
| Asset catalog | App icon + logo | Branding / splash |

---

## Internal “modules” (not packages)

Logical groupings inside the target:

- `Models`
- `Views` (+ Components / Shared / Stats)
- `DesignSystem`

Compiled into the application targets, not separate frameworks. On this branch those targets are iOS `Time4Skill` and macOS `Time4SkillMacOS`, both with bundle ID `com.etaosin.time4skill`. The shipping TimeToSkill app on `release/ver1.6` remains `gregkaps.TimeToSkill`.

---

## Monetization / Store identity

| Setting | Value |
|---------|-------|
| Time4Skill bundle ID (iOS and macOS targets) | `com.etaosin.time4skill` |
| TimeToSkill release bundle ID (`release/ver1.6`) | `gregkaps.TimeToSkill` |
| Historical TimeToSkill IAP product ID | `com.gregkaps.timetoskill.pro` (removed from this branch) |
| Marketing version | `1.6` on both Time4Skill application targets |
| Current project version (build) | iOS `17`, macOS `16` |

StoreKit Configuration (`.storekit`) file: **not present in repo** (local StoreKit testing config may be missing).
