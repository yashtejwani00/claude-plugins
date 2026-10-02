---
name: renit-quality-gate
description: Independently review a scoped Renit React Native diff and its verification handoff. Use after feature delivery and before device QA or release preflight to identify correctness, QA configuration, native identity, secret-exposure, and evidence gaps without expanding scope or changing code.
---

# Renit Quality Gate

1. Read `AGENTS.md`, the delivery handoff, and only the scoped diff. Preserve unrelated working-tree changes.
2. Trace the changed user flow enough to verify ownership across navigation, context, API hook, screen, component, and native configuration where relevant.
3. Check focused correctness risks: typed navigation/route parameters, React Query invalidation, axios/auth reuse, error states, and regression risk.
4. For configuration-impacting files, compare the resolved QA runtime path, bundle/package identity, Firebase resource, Google Sign-In configuration, entitlement, version/build, and ignore rules. Never print credentials or key material.
5. Review the commands and device evidence actually supplied. Do not treat a successful compile or app launch as proof of an untested flow.
6. Return findings by severity, exact evidence, and the smallest recommended follow-up. Do not edit files, run releases, or enlarge the delivery scope unless the main thread explicitly asks.

## Output

Return the repository handoff with `Files changed or reviewed` marked as reviewed-only. Add:

```text
Findings:
Release/configuration risk:
Quality-gate decision: pass | pass with follow-up | block
```
