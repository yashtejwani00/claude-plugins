---
name: renit-local-testflight-release
description: Create and upload a QA-configured Renit iOS archive to TestFlight using local Xcode rather than EAS. Use only after a passing release preflight and explicit user approval for the requested signing, archive, App Store Connect, compliance, or tester-distribution actions.
---

# Renit Local TestFlight Release

## Preconditions

1. Require a current `renit-release-preflight` handoff with no unresolved blocking gate.
2. Confirm the user explicitly approves the next external action. Ask again immediately before importing/trusting a certificate, changing signing, creating an archive, uploading, declaring export compliance, assigning testers, or submitting Beta App Review.
3. Use only `EXPO_PUBLIC_APP_ENV=QA` and `EXPO_PUBLIC_QA_API_HOST=qa-api.toratora.site`. Do not use EAS for this workflow.
4. Run `plugins/renit-agentic-dev/skills/renit-local-testflight-release/scripts/inspect-ios-release.sh` before archiving. Stop on a block; never guess or repair signing without approval. The approved archive helper is `plugins/renit-agentic-dev/skills/renit-local-testflight-release/scripts/archive-ios-qa.sh`.

## Local archive and upload

1. Use `ios/Renit.xcworkspace`, the `Renit` scheme, Release configuration, and generic iOS-device destination.
2. Confirm `com.renit.app`, team `43Q57TAAAQ`, Apple Distribution signing, App Store provisioning profile, `aps-environment`, and a new version/build number.
3. Archive with the QA variables in the same command/Xcode launch environment. Validate the archive before export/upload.
4. Upload with Xcode Organizer or an explicitly approved App Store Connect workflow. Record the archive path, version/build, upload result, and warnings.
5. In App Store Connect, wait for processing. Treat export compliance as a human legal declaration: present the exact question and intended answer, then wait for approval before saving.
6. Assign an internal/external group only after the user identifies it. Do not submit Beta App Review without explicit approval.

## Boundaries

- Never store or print Apple passwords, two-factor codes, `.p12`, `.p8`, profiles, device tokens, or QA account credentials.
- Never use an Expo cloud build or production endpoint as a shortcut.
- Do not claim a tester can install a build until App Store Connect shows the appropriate ready state and group assignment.

## Output

Return the standard handoff plus:

```text
Archive path:
Signed bundle/team/profile:
Version/build:
App Store Connect upload state:
TestFlight state and assigned group:
Warnings:
Next human gate:
```
