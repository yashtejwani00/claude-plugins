---
name: renit-release-preflight
description: Produce a read-only Renit release-readiness report covering QA/Prod configuration, native dependencies, scoped changes, and QA evidence. Use when Claude needs to assess a Renit EAS, store, or production release without publishing anything.
---

# Renit Release Preflight

## Read-only checks

1. Compare `eas.json`, Expo configuration, environment templates, and `src/lib/config.ts`. Flag QA/Prod endpoint drift or any local-backend value in the intended release path.
2. For a local iOS/TestFlight request, inspect version/build alignment, `com.renit.app`, Apple team, Release signing mode/profile, distribution identity, `aps-environment`, Firebase resource, Google Sign-In scheme, workspace/Podfile state, and the QA archive environment.
3. Inspect the Git diff and ignore rules for credentials, generated files, Firebase configuration, native patches, Podfile lock state, iOS workspace, signing, and version changes.
4. Verify the latest scoped delivery and quality-gate handoffs include passing relevant checks and device-QA evidence, or explicitly mark the missing evidence as a block.
5. Check that no QA fixture or local credential file is included in the release scope.
6. Report App Store Connect/TestFlight state only from current evidence. Flag export-compliance, tester group, Beta App Review, missing dSYM, or deployment-target warnings as applicable.

## Boundaries

- Do not run `eas build`, publish an update, submit a store build, alter signing, or change any cloud configuration.
- Report each gate as pass, block, or not-applicable with source evidence and the exact next action.
- Return the required handoff to the main thread, which obtains human approval before any release action.
