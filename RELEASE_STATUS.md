# Pet Fiasco v26.9.1 release status

Checked 2026-10-15. **Published and deployed with macOS pending.** The v26.9.1
release source is committed separately from preserved unrelated local changes.

## Implemented and verified

- Rebrand and planned web address: https://pet-fiasco.web.app.
- Firebase email/password accounts and owner-only Firestore cloud saves.
- Pet days, age, evolution, care journal, more frequent sounds, and three new sound themes.
- Anniversary banner and gift code removed; adoption birthdays remain separate.
- Hub → Egg Nest: choose a species, wait through a saved two-minute countdown,
  then hatch and adopt a new pet. Restart persistence and duplicate-hatch protection verified.
- First-run ten-step tutorial, completion persistence, and Settings → How to Play replay verified.
- Flutter tests: **39 passed** (`build/qa/flutter-test-final.log`).
- Live Firebase registration, sign-in, save/restore, anonymous denial, and cross-account
  denial passed. Disposable test accounts and saves removed (`build/qa/firebase-final.log`).
- Static analysis: no errors; two redundant-null-assertion warnings and style notices remain.
- APK signature, IPA ZIP integrity, web ZIP integrity, and DMG checksums verified.
- GitHub release published with checksum-verified APK, Sideloadly IPA, and web ZIP.
- Both Firebase sites deployed and their public manifests verified byte-for-byte.

## Local packages

In `build/releases/v26.9.1/`:

- `pet-fiasco-v26.9.1.apk` — version 26.9.1 / 26901; original Android signing certificate retained.
- `pet-fiasco-Sideloadly-v26.9.1.ipa` — unsigned, for signing with Sideloadly.
- `pet-fiasco-web-v26.9.1.zip` — includes the repaired Xenix download helper.
- `pet-fiasco-macos-v26.9.1-LOCAL-PREVIEW.dmg` — Intel and Apple Silicon;
  development-signed, **not a public distribution build**.

## Remaining macOS publication blocker

Automatic Developer ID export failed for Lina Ahmed team `9JZ8BU782J`:

> The selected team does not have a program membership that is eligible for this feature.

> No signing certificate "Developer ID Application" found

See `build/qa/macos-export.log`. The installed identity is Apple Development for
`lina.asem@hotmail.com`. The current embedded development profile is restricted to
one registered device and expires **2026-10-22 08:55:34 UTC**.

User action required: sign into Xcode with an eligible Apple Developer Program team
and provide/create a Developer ID Application certificate with its private key.
Enrollment, payment, and account approval were not performed.

## Remaining macOS gate

1. Export the existing `PetFiasco.xcarchive` using `tools/macos_export.plist` under
   an eligible team, then package a public Developer ID-signed DMG.
2. Add that DMG to the existing v26.9.1 release and restore the direct macOS
   download URL after verifying its public checksum.

Live release: https://github.com/zien95/kitty-adventure/releases/tag/v26.9.1

Live sites: https://pet-fiasco.web.app and https://kitty-adventure-zona.web.app.
The macOS manifest link currently opens the release status page instead of a missing
DMG. Firebase Auth configuration and owner-only Firestore rules are configured.
