# Project Overview — TimeToSkill

## What the application does

**TimeToSkill** is a privacy-focused iOS productivity app for tracking time invested in learning skills (e.g. piano, chess, coding). Progress is visualized against learning-theory thresholds (20h → 100h → 1,000h → 10,000h). The app also offers exemplary-skill self-evaluation, tap counters, motivational quotes, and statistics.

Tagline (from README): *Track your time. Learn smarter. Grow with patience.*

**Current marketed version:** 1.6 (build 14)  
**Developer:** Grzegorz Kulesza (`etaosin@gmail.com`)  
**License / legal:** see repo-root `LICENSE.md`, `TERMS.md`, `PRIVACY.md` / `PrivacyPolicy.md`

---

## Main purpose

Help users build deliberate practice habits by:

1. Logging time against named skills (timer + manual adjust).
2. Showing which learning “stage” they are in via color/progress UI.
3. Motivating with localized quotes and theory explanations.
4. Letting users self-rate exemplary achievements (with a verification gate).
5. Tracking simple increment/decrement counters (repetitions-style).

---

## Target users

**Assumed** (not explicitly segmented in code/docs):

- Self-learners and hobbyists who want a lightweight offline tracker.
- Users who prefer dark-mode focus and no accounts.
- International users — UI and content ship in ~40 locales.

---

## Main features

| Feature | Description | Monetization |
|--------|-------------|--------------|
| Skill time trackers | Create skills, start/stop timer, manual time adjust, sort list | Free |
| Learning theory | Explain 20h / 100h / 1k / 10k stages | Free |
| Motivational quotes | Random quote on home (localized JSON) | Free |
| Statistics | Totals, top skills, activity, global time distribution | Free |
| PDF export | Skills + counters + histograms via share sheet | Free |
| Time converter | Hours ↔ days (8/12/24h) ↔ years | Free |
| Exemplary Skills | Catalog of achievements; self-rate 0–3★ with code verification | Free (catalog) |
| Custom exemplary skills | User-created skills | **Pro unlock** (intended) |
| Reset daily evaluation limit | Bypass 5/day limit | **Pro unlock** (intended) |
| Counters | Tap/long-press counters with stage thresholds | Free |
| Lifetime Pro IAP | StoreKit 2 non-consumable `com.gregkaps.timetoskill.pro` | Paid |

**Coming soon** (README only, not implemented): cloud sync, achievements system expansion, better visuals, more counter UX.

---

## High-level user flow

```text
App launch
    → RootView (launch gate, `AppLaunch`)
        → SplashView (animated logo, ~12s) on launches 1, 32, 64, 128
            → MainView (home) — every other launch, and after the splash
            ├─ Manage Trackers → StartView → SkillProgressView / SkillOptionsSheet
            ├─ Manage Counters → ManageCountersView → CounterDetailView
            ├─ Learning Theory → TheoryView
            ├─ Exemplary Skills → ExemplarySkillsView → ExemplarySkillDetailView
            ├─ About → AboutView
            ├─ Options FAB → OptionsView (PDF export, time converter)
            ├─ Stats FAB → StatsView
            └─ Center FAB → PaywallView or CustomExemplarySkillSheet (Pro)
```

Persistence is local SwiftData. No login. No backend API.

---

## Screens available

| Screen / surface | File | Entry |
|------------------|------|--------|
| Launch gate | `RootView.swift` + `AppLaunch.swift` | App root: splash vs. main, App Store review on launches 16 & 256 |
| Splash | `SplashView.swift` | Root, on launches 1, 32, 64, 128 |
| Home / hub | `MainView.swift` | After splash / on other launches |
| Skill list / timers | `StartView.swift` | Nav from home |
| Add skill | `AddSkillView.swift` | Sheet |
| Skill options | `SkillOptionsSheet.swift` | Sheet |
| Per-skill time distribution | `TimeDistributionView.swift` | From skill options |
| Manage counters | `ManageCountersView.swift` | Nav from home |
| New counter / detail / thresholds | same file (`NewCounterSheet`, `CounterDetailView`, `ThresholdEditor`) | Sheets / nav |
| Theory | `TheoryView.swift` | Nav from home |
| Exemplary skills grid | `ExemplarySkillsView.swift` | Nav from home |
| Exemplary skill detail + verification | `ExemplarySkillDetailView.swift` | Sheet |
| Custom exemplary skill form | `CustomExemplarySkillSheet.swift` | Sheet (Pro) |
| About | `AboutView.swift` | Nav from home |
| Options | `OptionsView.swift` | Sheet |
| Stats overview | `StatsView.swift` | Sheet |
| Global time distribution | `GlobalTimeDistributionView.swift` | Embedded in stats |
| Paywall | `PaywallView.swift` | Sheet |
| Dev paywall (unused) | `DevPaywallView.swift` | **Not referenced** |
| Support developer (unused) | `SupportDeveloperView.swift` | **Not referenced** |

---

## Important business logic

### Skill time tracking

- `Skill.hours` accumulates elapsed timer time (`activeStart` → stop) and manual adjustments.
- Each stop/manual change inserts a `TimeIntervalEntry` (minutes + source: timer/manual).
- Stage colors/progress in `SkillProgressView` map hours to bands: &lt;21, &lt;100, &lt;1000, &lt;10000, &lt;100000.

**Assumption / gap:** `Skill.lastUpdated` is set only in `init` and is **never updated** when hours change. Stats that filter by `lastUpdated` (week/month/activity) are therefore unreliable.

### Exemplary skills

- Catalog JSON (`ExemplarySkills*.json`) seeded via `SkillSeeder` when `catalogVersion` increases.
- User ratings 0–3 stars; verification requires typing a randomly generated 12-character code.
- Free users: max **5 new evaluations per calendar day** (`ExemplarySkillConstants.dailyEvaluationLimit`).
- Re-evaluation of already-obtained skills skips the daily limit.
- Pro is supposed to unlock custom skills and daily-limit reset via `@AppStorage("customSkillUnlocked")`.

**Critical gap:** nowhere in the codebase is `customSkillUnlocked` written to `true` after a successful IAP. Unlock UI is gated on AppStorage, while StoreKit only sets `IAPManager.isPurchased`. See `KNOWN_ISSUES.md`.

### Counters

- Tap adds `step`; long-press subtracts `step`.
- Optional sorted thresholds drive `CounterRing` stage max.

### Monetization

- StoreKit 2 (`Product` / `Transaction`) via singleton `IAPManager`.
- Product ID: `com.gregkaps.timetoskill.pro`.
- Errors are largely swallowed (empty `catch`).

### Offline / privacy stance

Docs and FAQ claim fully offline / no account. StoreKit purchases require network to Apple. Privacy copy is inconsistent across `PRIVACY.md` vs `PrivacyPolicy.md`.

---

## Assumptions (explicit)

1. App is intended for App Store distribution under team `8TC5J5KMXE`, bundle `gregkaps.TimeToSkill`.
2. “40 languages” refers to localization folders + quote/skill JSON coverage (exact parity not audited line-by-line).
3. There is no separate backend; any future cloud sync is not started in this repo.
4. Dark mode only is intentional product design (`preferredColorScheme(.dark)`).
