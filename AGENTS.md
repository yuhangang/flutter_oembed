# AGENTS.md

## Purpose

This repository contains `flutter_oembed`, a Flutter package for rendering rich
social and media embeds on mobile platforms with provider-specific APIs and
WebView-based rendering.

Use this file as the default operating guide for any agent making changes here.
The main maintenance rule is simple:

- Any behavior change must be reflected in tests.
- Any user-visible or public API change must be reflected in docs.

## Repo Shape

- `lib/`: package source
- `test/`: unit and widget tests for library behavior
- `example/`: sample app used for manual verification and usage examples
- `tool/`: code generation helpers
- `.github/workflows/pull_request.yml`: CI contract for pull requests
- `README.md`: public package documentation
- `CHANGELOG.md`: release-facing summary of shipped changes
- `RELEASE_CHECKLIST.md`: release and verification policy

## Change Rules

### 1. Keep tests in sync with code

When changing implementation in `lib/`, update or add tests in the nearest
matching area under `test/`.

Examples:

- `lib/src/core/...` -> `test/core/...`
- `lib/src/services/...` -> `test/services/...`
- `lib/src/services/api/...` -> `test/services/api/...`
- `lib/src/widgets/...` -> `test/widgets/...`
- `lib/src/controllers/...` -> `test/controllers/...`
- `lib/src/utils/...` -> `test/utils/...`

Expected standard:

- Do not leave behavior changes untested.
- Prefer targeted tests for the changed contract over broad incidental coverage.
- If fixing a bug, add a regression test that fails before the fix.
- If changing provider matching, request building, cache behavior, rendering
  decisions, sizing, lifecycle, or error handling, tests are required.
- If changing exports or public constructor parameters, add or update tests that
  exercise the public API, not only private helpers.

### 2. Keep docs in sync with shipped behavior

Update `README.md` whenever a change affects any of the following:

- public API surface
- setup steps
- supported providers
- platform support
- credentials or configuration requirements
- rendering behavior
- sizing or layout behavior
- brightness/theme support
- caching behavior
- limitations, caveats, or defaults

Update `CHANGELOG.md` for any change intended to ship.

Update `example/` when the best usage pattern changes or when a new capability
should be demonstrated in the sample app.

### 3. Preserve accuracy over optimism

- Do not document planned behavior as if it already exists.
- Do not claim platform support that has not been verified.
- Do not claim provider support details unless they match the current code.
- Keep README examples aligned with actual exported APIs from
  `lib/flutter_oembed.dart`.

### 4. Keep this file up to date

`AGENTS.md` is a living guide and may be updated whenever needed.

Update this file when any of these change:

- CI workflow or required validation commands
- testing expectations or quality gates
- documentation policy
- release process or contributor workflow
- repository structure that affects agent behavior

## Provider And Generator Notes

Take extra care when touching provider-related code:

- `lib/src/services/providers_snapshot.dart` is generated data and should stay
  consistent with the generator when provider source data changes.
- If provider discovery data or generation logic changes, run the generator and
  commit the updated generated output.
- If a provider is added, removed, or materially changed, update README provider
  tables and add or update focused tests.

## Validation Checklist

Before considering the task complete, run the checks that match the CI workflow
and affected scope.

Baseline checks from repo root:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
(cd example && flutter analyze)
flutter test --coverage
dart pub publish --dry-run
```

Dependency-related changes:

- Run `flutter pub get` in the repo root if `pubspec.yaml` changes.
- Run `flutter pub get` in `example/` if `example/pubspec.yaml` changes.
- Commit any intentional lockfile updates.

Provider snapshot changes:

- Run the relevant generator under `tool/`.
- Verify generated files are committed.

## Review Heuristics

Before finishing, check these questions:

- Did I change runtime behavior without adding or updating a test?
- Did I change a public API or user-visible behavior without updating docs?
- Did I update the example app if the recommended usage changed?
- Did I update the changelog if this is a shippable change?
- Did I keep claims in the README strictly true for the current codebase?

If any answer is "yes", fix that before handing off.
