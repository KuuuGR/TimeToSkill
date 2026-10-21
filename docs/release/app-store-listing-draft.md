# Time4Skill — App Store listing draft (not published)

Prepared from the current `Time4Skill-MacOS` codebase. **Do not paste into
App Store Connect without owner review.** This is not an App Review decision.

## Identity (already in project — do not change without need)

- Display name: **Time4Skill**
- Bundle ID: `com.etaosin.time4skill`
- Team: `8TC5J5KMXE`
- Marketing / build at draft time: **1.8 (19)** (iOS & macOS targets)
- ASC app Apple ID (from prior docs): `6816741946`

## Suggested subtitle

Practice hours, balances, and skill milestones — offline on your device.

## Promotional text (optional, short)

Measure deliberate practice with timers, time balances, a large skill catalog,
activity calendars, and learning-theory stages — no account required.

## Description (draft)

Time4Skill helps you see the hours you invest in learning.

TRACK PRACTICE
• Start/stop timers per skill, or add hours manually
• Progress stages inspired by learning-theory milestones (20h → 100h → 1,000h → 10,000h)
• Separate Time Balance tool for countdown / count-up that is not skill lifetime hours

CATALOG & COUNTERS
• Browse a large bundled catalog of exemplary skills, favourite them, and rate yourself
• Add custom skills (optional photo via the system picker)
• Tap counters for repetitions and elapsed-day counters

INSIGHTS
• Session-duration histograms per skill and overall
• Year and month activity calendars from completed timer sessions
• PDF export of a local summary from Options

LANGUAGES
• Dozens of interface languages
• Interslavic with Latin, Cyrillic, and Glagolitic scripts

PLATFORMS
• iPhone, iPad, and Mac
• Dark interface, no account, practice data stored on device

Time4Skill is a separate app from TimeToSkill. It shares the idea of measuring
practice hours, but adds time balances, a much larger catalog, activity
calendars, in-app language/script selection, and a native Mac experience.

## Keywords (draft, ≤100 characters — trim before use)

practice,skills,timer,habits,learning,hours,catalog,stats,offline,interslavic

## What’s New (for 1.8)

• Time Balance countdown / count-up trackers
• Expanded exemplary-skills catalog
• Activity calendars and refined session charts
• In-app language selection including Interslavic scripts
• Native macOS app
• Privacy manifest and clearer privacy documentation

## App Review notes (draft)

Time4Skill (com.etaosin.time4skill) is a distinct product from our existing
TimeToSkill (gregkaps.TimeToSkill). Both help users measure practice time, but
Time4Skill is not a skin of the same binary:

Confirmed functional differences in the current codebase:
1. Time Balance (`TimeBudget`) — remaining-time up/down trackers independent of skill hours
2. Exemplary skills catalog on the order of ~2,000 bundled items vs tens in TimeToSkill 1.6
3. Year/month activity calendars driven by completed timer sessions
4. In-app language picker with Interslavic Latin / Cyrillic / Glagolitic
5. Native macOS target with sidebar navigation
6. No in-app purchase layer in Time4Skill (TimeToSkill 1.6 still documents a Pro unlock)

We intend both apps to coexist. Reviewers can exercise: create a skill → start/stop
timer → open Time Balance → open Statistics calendars → open Language settings →
export PDF from Options. No login is required.

## Screenshot checklist (owner to capture)

iPhone 6.7" / 6.5" and iPad 13":
1. Home / overview with tracked hours
2. Skill list with timer Start/Stop
3. Time Balance screen
4. Statistics (histogram or calendar)
5. Skill catalog
6. Language / Interslavic script picker
7. Theory or Time Converter

Mac:
1. Sidebar + overview
2. Trackers
3. Statistics / catalog

## App Privacy questionnaire — facts for the owner

| Question theme | Fact from code |
|---|---|
| Account | None |
| Tracking (ATT) | Not used; privacy manifest sets NSPrivacyTracking = false |
| Analytics / ads SDKs | None in sources |
| Data linked to user identity | No Time4Skill account identity |
| Data used to track | Not implemented |
| Contact info collected by app | Not collected by app code |
| User content | Skills/counters/images stored on device; PDF share is user-initiated |
| Diagnostics | No third-party crash reporter in sources |
| External links | Optional Safari opens (wiki, DOI, PayPal.me) |
| Purchases | No IAP in current Time4Skill sources |
| Required-reason APIs | UserDefaults CA92.1; File timestamp C617.1 in PrivacyInfo.xcprivacy |

Owner must still complete ASC Nutrition Labels to match this draft and their own judgment.

## Versioning recommendation

Keep marketing version on the Time4Skill line (currently 1.8). Build numbers must
stay strictly increasing for `com.etaosin.time4skill` (already past 18). Do not
reuse build 7.
