---
name: renit-device-qa
description: Run controlled Renit QA flows on Android or a connected iPhone, collect device evidence, and safely manage agent-owned QA fixtures. Use when Codex needs physical-device validation of a scoped Renit flow after review.
---

# Renit Device QA

## Availability gate

Run only when the device-QA worker is available as `gpt-5.6-luna` at high reasoning. Until then, the main thread must report this skill as unavailable and must not substitute another model.

## QA controls

1. Run `renit-dev-bootstrap` and require its successful QA-only preflight.
2. Read local normal-user credentials (`user_one` and `user_two`) from `config/environments/qa-test-accounts.local.json` without printing them.
3. Use only QA endpoints and only fixtures labelled `AGENT_QA_<run-id>`.
4. Create or mutate a listing, message, offer, review, or account only when it is required by the selected flow. Clean up agent-owned fixtures where the API permits.
5. Select a named regression flow and record its app build/version, QA host, account role, fixture identifiers, screenshots, and focused logs. Launch-only evidence is not sufficient for a flow pass.

## Platform workflow

- **Android:** verify ADB, install the QA build, drive available UI/device controls, and capture focused logcat, screenshot, and UI-hierarchy evidence.
- **iPhone:** use the workspace, Xcode, and `xcrun devicectl` for build, install, launch, and logs. Ask the user for certificate trust, OAuth, or system permission actions.
- **Regression flows:** cover the relevant subset of QA home load, normal-user sign-in, browse/product details, contact-owner/chat, listing, and push registration. Do not force an unavailable third-party sign-in or system prompt.
- Do not add XCUITest, Maestro, Detox, or a new test framework in this workflow.

## Output

Record the selected QA flow, device, account roles, fixture IDs, observed result, cleanup result, and relevant artifacts. Classify failures as app, QA backend, device, signing, or human-gated; never guess.
