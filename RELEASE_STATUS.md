# Pet Fiasco v26.10.0 release status

## Final result — published and deployed 2026-10-16

- Release: https://github.com/zien95/kitty-adventure/releases/tag/v26.10.0
- All four GitHub assets matched local sizes and SHA-256 digests, then each
  public download was downloaded again and checksum-verified.
- Both Firebase Hosting sites were deployed. Live manifests, all four download
  links, version 26.10.0 / 261000, and byte-identical application JavaScript were
  verified at pet-fiasco.web.app, kitty-adventure-zona.web.app, and
  kitty-adventure-zona.firebaseapp.com.
- macOS is Apple Silicon only, ad-hoc signed and unnotarized as requested.
  It launched locally. Authentication persistence after removing team-bound
  keychain entitlements has not been independently exercised on another Mac.
- Current web ZIP SHA-256: `d32baabe86949b62b52b61ce3c3ba4b3f1e19f438f5d6d3abeca270c02c6ee26`.
- Current ad-hoc DMG SHA-256: `a3138029735b2d0c235d6ec93d7b36c2da143a7a2caba1e761bf18c2f6bdecb8`.
- APK and IPA checksums below are unchanged. Flutter suite: 49 tests passed.
- Release source: `5845794c`. Unrelated dirty files remain preserved.

Earlier checkpoints below are retained as history and superseded by this result.

## Ad-hoc release authorization — 2026-10-16

The user explicitly authorized ad-hoc macOS distribution, superseding the
Developer ID gate described below. The Apple Silicon app was re-signed ad-hoc
after removing its device-restricted profile and team-bound entitlements. It
launched successfully locally; its DMG passed signature and image verification.
The public package is `pet-fiasco-macos-v26.10.0-arm64-ADHOC.dmg` and is
unnotarized. The download page discloses the macOS approval requirement.
The following earlier checkpoint records the pre-authorization state.

Checked 2026-10-16. **Feature-complete and packaged locally; publication is
blocked by macOS distribution signing.** The live sites and public updater remain
on v26.9.1 so they do not advertise download URLs that are not available yet.

## Implemented and verified

- Third-person pet yard with real X/Y/Z simulation, visible coordinates, camera
  rotation, desktop keyboard controls, and mobile joystick/action controls.
- Pets can approach the food bowl and jump onto it to eat; birds can fly up and
  down and the camera follows their altitude.
- Generated character art for cat, dog, bunny, fox, panda, bird, and elephant,
  with five age stages and eight mood expressions.
- Elephant adoption, Gentle Giant Grove habitat, Animal Almanac entry, Pet
  Parade support, and real CC0 elephant call with in-app attribution.
- Pet Parade, Animal Almanac, sound credits/packs, daily streak, first-run tour,
  and Settings -> How to Play replay were exercised in the release web build.
- Flutter tests: **49 passed**.
- APK, IPA, web ZIP, app signature, and DMG integrity checks passed.

## Local packages

In `build/releases/v26.10.0/`:

- `pet-fiasco-v26.10.0.apk` — 26.10.0 / 261000.
- `pet-fiasco-Sideloadly-v26.10.0.ipa` — unsigned, for signing with Sideloadly.
- `pet-fiasco-web-v26.10.0.zip` — release-mode Firebase Hosting bundle.
- `pet-fiasco-macos-v26.10.0-arm64-LOCAL-PREVIEW.dmg` — Apple Silicon,
  development-signed, **not a public distribution build**.

SHA-256 checksums:

- APK: `782c501d79add2a24dbc492c70f554486bfc2c2a215924639bef796b4bc3222d`
- Sideloadly IPA: `c48178c274427e0ac7f181ea32d7f6947f456b819ca57e47801e5d70299c3098`
- Web ZIP: `a1c064761be3e45053a3f57df051bfcd0ae3a46fa7a401e7b780aca9590849e6`
- macOS local preview: `0d1dd76d5bd7159a791f518a075f438ffe02992237df0d5439f03b6f99e09bc0`

## Publication blocker

The keychain has an `Apple Development` identity for team `9JZ8BU782J`, but no
`Developer ID Application` identity and private key. The development profile is
restricted to this registered Mac, so its DMG cannot be the public macOS release
asset. The verified-release publisher correctly rejects it.

User action required: sign in to Xcode with a team enrolled in the Apple
Developer Program that is eligible for Developer ID distribution, then create or
install a `Developer ID Application` certificate with its private key. Rebuild a
Developer ID-signed (preferably universal) DMG, notarize it, and verify that
public download before publishing.

## Held publication steps

No v26.10.0 GitHub release was published, no v26.10.0 `latest.json` was deployed,
and neither Firebase Hosting site was updated. After the Mac gate is cleared:

1. Build and verify the public Mac DMG.
2. Update both manifests and the download page with the four exact asset names.
3. Commit the reviewed release source and manifests.
4. Upload a draft GitHub release; compare remote sizes and SHA-256 digests.
5. Publish only after all four public download URLs pass checksum verification.
6. Deploy both Firebase Hosting sites, then re-fetch each live manifest, download
   page, and compiled application script.
