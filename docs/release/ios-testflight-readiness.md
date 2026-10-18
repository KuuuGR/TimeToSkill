# iOS TestFlight readiness

Checked on 2026-10-18. No App Review submission was made. Testers were not added.

## Target

- Project: `TimeToSkill/TimeToSkill.xcodeproj`
- Shared scheme: `Time4Skill`
- Target: `Time4Skill` (iOS; product `Time4Skill.app`)
- Bundle ID: `com.etaosin.time4skill`
- Marketing version: `1.6`
- Build number: `18`
- Team: `8TC5J5KMXE`
- Signing style in the project: Automatic
- Deployment target: iOS 18.2
- Devices: iPhone and iPad (`TARGETED_DEVICE_FAMILY` 1,2)

`CURRENT_PROJECT_VERSION` is set on the iOS target, not on the project. Debug and Release are both `18`. The macOS target `Time4SkillMacOS` keeps its own build `16`. There is no `.xcconfig` overriding the build number. Marketing version was not changed.

## Status of build 18

- `BUILD SUCCEEDED`
- `ARCHIVE SUCCEEDED`
- `EXPORT SUCCEEDED`
- `UPLOAD ACCEPTED`
- `PROCESSING`
- `READY FOR TESTING` is not confirmed

App Store Connect returned upload state `PROCESSING` at 13:08:37 on 2026-10-18. Xcode then reported `Uploaded package is processing` and `Upload succeeded`.

## Archive

`xcodebuild -scheme Time4Skill -configuration Release -destination generic/platform=iOS archive` succeeded.

Archive: `/tmp/t4s-testflight/build18/Time4Skill.xcarchive`

The archive contains `Products/Applications/Time4Skill.app` for `iphoneos` arm64. Archive Info.plist records bundle `com.etaosin.time4skill`, version `1.6`, build `18`.

## Export

App Store Connect export used automatic signing and `manageAppVersionAndBuildNumber` false.

IPA: `/tmp/t4s-testflight/build18/export/Time4Skill.ipa`

Unpacked IPA Info.plist: bundle `com.etaosin.time4skill`, version `1.6`, build `18`, platform `iphoneos`. Signature: `Apple Distribution: Grzegorz Kulesza (8TC5J5KMXE)`. Profile: `iOS Team Store Provisioning Profile: com.etaosin.time4skill`. `get-task-allow` is false. `beta-reports-active` is true.

## Upload

Upload used the build 18 archive, destination `upload`, and the same export options. App Store Connect accepted it.

- App: Time4Skill, Apple ID `6816741946`
- Build upload ID: `1f18390c-ab5d-4631-90b1-92f44811705c`
- Asset upload state: `COMPLETE`
- Package state returned by App Store Connect: `PROCESSING`

The earlier build 17 archive and IPA were left in place and were not uploaded again.

## Earlier build 17 attempt

Archive `/tmp/t4s-testflight/Time4Skill.xcarchive` and IPA `/tmp/t4s-testflight/export17/Time4Skill.ipa` are version `1.6` build `17`. Upload was rejected:

`The provided entity includes an attribute with a value that has already been used. The bundle version must be higher than the previously uploaded version: ‘17’. (ID: 4a545020-f9ca-4ca4-893f-64acd8857339).`

A separate unused IPA at `/tmp/t4s-testflight/export/Time4Skill.ipa` had build `18` only because an earlier export left `manageAppVersionAndBuildNumber` at the Xcode default. That file was not uploaded. The accepted build 18 comes from the new archive after `CURRENT_PROJECT_VERSION` was set to 18.

## What to do when processing finishes

This is an instruction only. Testers were not added and the account was not changed.

1. Open App Store Connect, app Time4Skill, TestFlight, platform iOS.
2. Confirm version `1.6` build `18`. Wait until the status leaves processing. Missing compliance or a processing error is shown on that build.
3. For internal testing, open TestFlight, Internal Testing, and create an internal group if one does not exist. Internal testers are people who already belong to the App Store Connect team.
4. Add those people to the group.
5. Add build `18` to that group. Internal testing does not use external TestFlight review.

Do not submit the version to App Review for this test build.

## Other checks

App icons for iOS, including 1024, are assigned in `AppIcon.appiconset`. Photos access in the app is `PhotosPicker`. No iOS entitlements file is set.

`TimeToSkill/TimeToSkill/Resources/.last_marketing_version` is `1.6`, so the catalog-version build phase did not rewrite `ExemplarySkills` JSON during this archive.
