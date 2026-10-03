---
name: renit-ticket
description: Take one Renit Jira ticket from key to a merge-ready PR without supervision - branch and worktrees in rn-app and rn-api, read the ticket, plan if it is large, implement, independent review, QA deploy, iOS simulator test, PR, final review, then merge once Yash approves. Use when the user gives a Jira key or URL (ENG-123) to work on, or says start, pick up or resume a ticket.
---

# Renit Ticket Pipeline

Yash hands over a ticket and comes back to a PR that is ready to merge. Between
those two points you run the whole thing. He reads the chat afterwards, so keep
a short running note of what you did and why, but do not wait for him.

## Who decides what

**Yash decides** only these. Anything not on this list is yours.

- The plan for large work (step 3), and the merge (step 9).
- A choice that changes what a user sees or pays, where the ticket, the vision
  doc and the existing code all fail to answer it. Ask one specific question
  with your recommendation, and carry on with everything that does not hinge on it.
- Signing in on the simulator when it is logged out, a QA deploy that
  `qa-deploy.sh` refuses, and everything under "Human approval gates" in
  rn-app's `AGENTS.md` (signing, archives, TestFlight, `qa-*` tags, EAS,
  Firebase deploys, credentials, production).

**You decide** everything else, including which review findings to fix. Fix what
affects a user, data, security or correctness. Skip what is cosmetic or
speculative. Record both in the PR under "Decisions" and "Skipped" with a
one-line reason each - that record is what replaces asking.

**Already approved inside this flow** (Yash, 2026-10-04): creating the branch
and worktrees, committing to the ticket branch, pushing the ticket branch,
opening the PR, moving and commenting on this Jira ticket, deploying the ticket
branch to QA through `qa-deploy.sh`, and creating and removing `AGENT_QA_<KEY>`
fixtures. This overrides "commit only when asked, never push unasked" for the
ticket branch only. It does not cover `main`, `master`, tags, or other tickets.

## 1. Set up

1. Read the ticket with the Atlassian tools: description, comments, parent,
   sub-tasks, links, attachments. A ticket is often a pasted WhatsApp message;
   work out what the reporter actually hit before deciding what to build.
2. Run `scripts/ticket-worktrees.sh <KEY> "<Jira summary>"` (path is relative to
   this skill's base directory). It creates `rn-app-<key>` and `rn-api-<key>`
   beside the main checkouts on a branch named `<KEY>-<Summary>`, cut from the
   latest `origin/main` and `origin/master`. For a sub-task whose story has a
   parent branch, pass that branch as the third argument.
3. Work only in those two worktrees, by absolute path. The main checkouts stay
   on whatever Yash has there. If the worktrees are outside the session's
   folders, add both to the session once, up front, so later edits do not each
   stop for permission.
4. Move the ticket to In Progress.

If the worktrees already exist, this is a resume: read the Jira status, the
branch log and any open PR, and continue from the first step that is not done.

## 2. Size it

**Small - build straight away, no review of a plan:** a bug, a copy or style
change, one screen or one endpoint, no new API contract, no data-rewriting
migration, no new navigation flow.

**Large - plan first:** an epic; a story that changes the contract between app
and API; a new multi-screen flow; a migration that rewrites existing rows;
anything in auth, payments, KYC, `firestore.rules` or native configuration.

Unsure? Treat it as small, post a five-line approach as a Jira comment, and go.

## 3. Plan (large work only)

Read `/Users/zineone/git/renit/docs/renit-product-vision-v3.md` and anything
relevant under `/Users/zineone/git/renit/docs/feature/` first; the plan has to move the product toward
that vision, not just close the ticket. Plan the complete feature in the fewest
phases that can each ship - do not defer the hard half to a "v2".

Write `/Users/zineone/git/renit/docs/feature/<KEY>-<slug>/plan.md`:
the user outcome, what is in and out, the API contract, data model and
migration, screens and states, the simulator flows that will prove it, the
build order, and every open decision with the default you chose. For an epic,
list the sub-tasks; after approval create them in Jira and run each through
this pipeline against a parent branch (sub-task PRs target the parent; one
final PR goes to `main`/`master`).

Have one fresh subagent attack the plan (the `Plan` agent, with the ticket and
the plan path), fix what it finds, post a summary on the ticket, and ask Yash to
review. This is the first of the two planned stops.

## 4. Build

- If the API contract changes, do rn-api first so the app builds against the
  real thing.
- rn-app follows `renit-feature-delivery`; rn-api follows its `CLAUDE.md`.
- Add or update unit tests for new logic. Checks before review:
  - rn-app: `npx tsc --noEmit` and `npx jest --watchAll=false`.
  - rn-api: the Django tests and `ruff` in throwaway containers on the QA
    server, never `docker compose exec` on the deployed stack. The exact
    commands are in `references/recipes.md`.
- Commit with `renit-commit`.

## 5. Review

Spawn the `renit-agentic-dev:renit-reviewer` agent once per repo that changed, in parallel, pass `code`.
Give each the ticket text, the worktree path and the base branch - not your
opinion of the change. Fix `high` and `med`. Fix `low` when it is quick,
otherwise list it under "Skipped". If the fixes were more than trivial, have
the reviewer look at the fix diff once more; after two rounds, move on unless
the decision is `block`.

## 6. Test on QA and the simulator

1. Push the ticket branches.
2. If rn-api changed: `scripts/qa-deploy.sh <KEY> <branch>`. It takes the QA
   lock, deploys, and proves the container runs the new code. Exit 3 (another
   ticket holds QA), 4 or 5 (deploying would lose someone's work) are for Yash;
   say which and stop the backend half there. Do not work around the lock or
   delete it; carry on with whatever the app side can prove without the new backend.
3. Simulator: boot the iPhone simulator, start Metro from the app worktree with
   `npm run start:qa`, and open the installed dev client. A native rebuild is
   only needed when a native dependency or native config changed; then run
   rn-app's `scripts/smoke-native-build.sh` too. Read the simulator section of
   `references/recipes.md` before the first tap: coordinates are in points.
4. Check the Profile tab first. If the app is signed out and the ticket touches
   signed-in screens, ask Yash to sign in - you do not type passwords - and
   test the signed-out flows while you wait.
5. Drive each acceptance point of the ticket as a user would, plus the nearest
   flows the change could break. A launch that does not crash proves nothing.
   Screenshot each result. Use only fixtures labelled `AGENT_QA_<KEY>` and
   remove them afterwards.
6. Anything wrong: fix it, re-run the checks from step 4, re-review if the fix
   is not trivial, deploy and test again. Repeat until the flows pass.

Android is not part of this flow unless the ticket is about Android; then use
`android-tester`, which needs Yash's device clearance.

## 7. Raise the PR

One PR per repo that changed, `gh pr create` against `main`/`master` (or the
parent branch). Title `<KEY>: <what changed>`. Body: what and why, how it was
tested (flows and evidence), Decisions, Skipped, Not tested, and a link to the
other repo's PR. No AI attribution. If a repo ended up with no changes, remove
its worktree and delete its local branch. Move the ticket to In Review.

## 8. Final review

Spawn a fresh `renit-reviewer` per PR, pass `pr`. Fix and push what it finds.
Then check for leftovers yourself: fixtures removed, Metro stopped, nothing
uncommitted, docs and comments match the new behaviour.

Then tell Yash, and post the same on the ticket:

```text
<KEY> is ready to merge.
PRs:
What changed:
Tested: (flows, with screenshots)
Not tested: (and why)
Decisions I made:
Skipped:
```

This is the second planned stop. Do not merge.

## 9. After Yash approves

1. `gh pr merge`: rn-api first with `--squash`, then rn-app with `--merge`. A
   hook turns this into a confirmation prompt; that click is his approval.
2. If rn-api was deployed: `scripts/qa-deploy.sh <KEY> master --release` puts
   QA back on `master` and frees the lock. For a sub-task, deploy the parent
   branch instead.
3. Move the ticket to In Testing, then Done.
4. Remove both worktrees and delete the local branches.

Merging does not start a store build. Never push a `qa-*` tag.
