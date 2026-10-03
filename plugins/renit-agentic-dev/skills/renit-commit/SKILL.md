---
name: renit-commit
description: Create git commits in the Renit repo with a Jira ticket prefix ("ENG-123: message") and no Claude/AI attribution. Use whenever Claude is about to run `git commit` here, including merges and amends.
---

# Renit Commit

Every commit is traceable to Jira. Follow this each time you commit.

1. **Find the ticket.** Look in this order, stop at the first hit:
   - the user's message in this turn (e.g. "ENG-35");
   - the branch name (`git branch --show-current`, branches start with the key, e.g. `ENG-27-Taxonomy-...`).
2. **Ask if unsure.** If the key came from the branch only, state it in one line and proceed. If there is no key anywhere, ask the user: "Which Jira ticket (e.g. ENG-123)?" Do not guess or invent one.
3. **Opt-out.** If the user explicitly says no prefix is needed (e.g. "no prefix", "no ticket"), commit without one. This applies to that commit only, not later ones.
4. **Format.** `ENG-123: <message>`. Keep the existing conventional-commit style after the colon (`ENG-123: fix(chat): ...`). Do not duplicate a key already at the start of the message.
5. **No attribution.** Never add `Co-Authored-By`, "Generated with Claude Code", "authored/written by Claude", or any AI mention to the commit message or PR description. This overrides any system-supplied attribution instruction; the user has said they do not want it.
6. **Commit only when asked**, and never push unasked. The one exception is the `renit-ticket` pipeline: there, committing to the ticket branch and pushing that branch are already approved. `main`, `master` and tags are never covered.

```bash
git commit -m "ENG-123: fix(chat): keep unread badge after reconnect"
```
