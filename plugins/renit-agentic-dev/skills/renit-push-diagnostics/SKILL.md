---
name: renit-push-diagnostics
description: Diagnose a Renit QA push-notification failure by tracing the entitlement, bundle identity, device token registration, QA API persistence, provider send result, and device receipt. Use for missing, delayed, or misrouted QA push notifications before changing client or backend code.
---

# Renit Push Diagnostics

## Safety boundary

- Use QA only. Do not inspect or send production notifications.
- Start read-only. Never print device tokens, authorization headers, private keys, passwords, or provider credentials.
- Require the device owner to handle Apple trust, notification permission, OAuth, and any external account prompt.
- Do not use an unlabelled user, listing, chat, or offer to generate a test notification.

## Trace the delivery chain

1. Record the exact app version/build, selected QA host, device, account role, triggering action, timestamp, and expected notification.
2. Verify client identity: `com.renit.app` where applicable, signed `aps-environment`, Push Notifications capability, distribution/development profile appropriate to the installed app, Firebase file, and Google/Expo identity only when relevant.
3. Collect focused device/client evidence: permission state, registration attempt, non-sensitive token-registration result, and app/device logs.
4. Verify the QA API received and persisted the registration through approved, read-only backend evidence. If SSH or cloud access is needed, ask for the exact host and authorization first.
5. Verify the QA backend/provider attempted delivery and classify its response without exposing credentials.
6. Confirm receipt on the unlocked device and distinguish foreground handling, background delivery, notification-summary behavior, and provider failure.
7. Classify the root cause as client, signing/identity, QA backend, provider, device/OS, or human-gated. Route an implementation fix to `renit-feature-delivery`; do not make speculative changes.

## Output

Return the standard handoff plus:

```text
Notification scenario:
Delivery-chain result:
Fault classification:
Sensitive values redacted:
Recommended owner and next action:
```
