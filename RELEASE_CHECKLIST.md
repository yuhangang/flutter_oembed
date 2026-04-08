# Release Checklist

Use this checklist before publishing `flutter_oembed`.

## Release Scope

- `1.0.0` is a stability release.
- Do not add new public APIs unless they are required for correctness.
- If a blocker fix forces an API break, cut a release candidate before publishing stable.

## Version And Docs

- Confirm [pubspec.yaml](/Users/yuhang.ang/Desktop/Projects/flutter_oembed/pubspec.yaml) has the intended release version.
- Confirm [README.md](/Users/yuhang.ang/Desktop/Projects/flutter_oembed/README.md) matches the version line being published.
- Confirm platform support and Flutter Web status are stated explicitly.
- Confirm provider credential requirements and known limitations are accurate.

## Required Automated Checks

Run these from the repo root:

```bash
flutter test
dart analyze
dart pub publish --dry-run
./scripts/coverage.sh
```

## Coverage Policy

- Coverage is measured from `coverage/filtered_lcov.info`.
- The filtered report intentionally excludes:
  - `lib/src/models/*`
  - `lib/src/logging/*`
  - `*.g.dart`
- If a coverage threshold is enforced for release, evaluate it against the filtered report, not the raw `coverage/lcov.info`.

## Minimum Manual Verification

Verify on both Android and iOS:

1. Render at least one provider from each category:
   - social: X or Reddit
   - video: YouTube or Vimeo
   - audio: Spotify or SoundCloud
2. Verify one Meta provider with valid credentials.
3. Verify iframe mode for YouTube.
4. Verify error states:
   - invalid URL
   - no internet
   - provider restriction or credential failure
5. Verify an embed list with multiple cards scrolls without crashes.
6. Verify the example app builds and runs.

## Publish Decision

Publish only when:

- automated checks pass
- manual checks pass
- no unresolved lifecycle or provider-resolution regressions remain
- docs describe the shipped behavior, not planned future behavior
