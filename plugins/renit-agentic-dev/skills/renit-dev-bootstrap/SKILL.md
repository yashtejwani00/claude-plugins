---
name: renit-dev-bootstrap
description: Validate and prepare the Renit React Native app for QA-backed local development on Android or a connected iPhone. Use when Claude needs to start, repair, or verify the Renit development environment, Expo configuration, native dependencies, or device connection.
---

# Renit QA Bootstrap

## Preconditions

- Work from the repository root.
- Use QA only. Do not start a local backend or set `EXPO_PUBLIC_APP_ENV=DEV` unless the user explicitly overrides this rule.
- Run `plugins/renit-agentic-dev/skills/renit-dev-bootstrap/scripts/validate-qa-setup.sh` first. Exit code `2` means the local credential file is missing; stop safely and tell the user how to create it from `config/environments/qa-test-accounts.example.json`.

## Workflow

1. Confirm `config/environments/qa.env.example`, `eas.json`, `app.config.js`, and `src/lib/config.ts` resolve `qa-api.toratora.site` and no local-backend fallback.
2. Install JavaScript dependencies with `npm ci` when dependencies are absent or the lockfile changed. Confirm `patch-package` applies the tracked patches.
3. Run `npx expo config --type public` with the QA environment before building or starting Metro. Check the resolved Android QA package/Expo identity when Android is selected.
4. For Android, verify `adb devices`, the QA Firebase file, build/install the selected QA development target, and collect `adb logcat` evidence.
5. For iPhone, use `ios/Renit.xcworkspace`, verify CocoaPods, `GoogleService-Info.plist`, the Google Sign-In URL scheme, and `Renit.entitlements` before using Xcode or `xcrun devicectl` to build, install, launch, and collect logs.
6. Use the validate script as the baseline preflight. It must stop safely when QA credentials are absent and must never print their values.
7. Ask for Apple trust, OAuth, signing, or permission actions instead of attempting to bypass them.

## Output

Return the required repository handoff (see `CLAUDE.md` → Required handoff). Include the resolved app environment, selected device, native build path, identity checks, and every blocker. Do not expose credential values.
