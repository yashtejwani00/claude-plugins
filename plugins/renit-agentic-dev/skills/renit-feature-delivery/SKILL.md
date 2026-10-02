---
name: renit-feature-delivery
description: Deliver a scoped Renit React Native feature or bug fix through the correct navigation, context, API, component, and native ownership layers. Use when Codex needs to implement, modify, or verify a targeted Renit app change before independent review and device QA.
---

# Renit Feature Delivery

## Workflow

1. Read `AGENTS.md`, identify the user-visible flow, and trace it through navigation, state context, API hook, screen, and reusable component before editing.
2. Preserve unrelated working-tree changes. Implement the smallest change at the owning layer; do not start a backend or use a non-QA runtime.
3. Treat changes to `app.json`, `app.config.js`, `eas.json`, Firebase files, plist files, entitlements, Podfile, or Xcode project settings as configuration-impacting. Validate the resolved QA Expo configuration and required native resource/identity before calling the change complete.
4. Run the narrowest relevant checks. Use `npx tsc --noEmit`, Jest, Expo config validation, or a native build only when the changed surface needs it.
5. Inspect the diff for accidental secrets, fixture data, generated artifacts, or changes outside the requested flow.
6. Return the required handoff for the quality gate. Do not self-approve a release.

## Boundaries

- Keep controller-like navigation code thin and place state/API behavior in its current owning context or backend hook.
- Reuse typed navigation and `axiosInstance`; do not add a parallel network or state layer for a one-off change.
- Treat QA credentials and `AGENT_QA_<run-id>` fixtures as test-only data and never commit them.
