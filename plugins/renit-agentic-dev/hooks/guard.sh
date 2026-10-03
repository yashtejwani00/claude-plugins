#!/usr/bin/env bash
# PreToolUse(Bash): the ticket pipeline runs unattended, so the actions that stay
# human are enforced here rather than left to the prompt.
#   deny: push to main/master, qa-* tags (they start store builds), EAS, firebase deploy
#   ask:  gh pr merge (Yash's click is the merge approval), gh workflow run
# Applies to Renit only: a session inside the renit folder, or a command that names it.
input=$(cat)
raw=$(jq -r '.tool_input.command // ""' <<<"$input")
case "$(jq -r '.cwd // ""' <<<"$input") $raw" in */renit/*|*/renit\ *|*simplyrenit*) ;; *) exit 0 ;; esac
# Quoted text (a commit message, a PR body) is not a command; blank it out so
# prose that mentions "git push origin main" is not mistaken for one.
cmd=$(perl -0pe 's/"[^"]*"/Q/g; s/\x27[^\x27]*\x27/Q/g' <<<"$raw")

decide() {
  jq -n --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
  exit 0
}
has() { grep -qE -- "$1" <<<"$cmd"; }

GIT='git( +-C +[^ ]+)?'
has "$GIT +push( [^;&|]*)? +\+?([^ ;&|]+:)?(refs/heads/)?(main|master)( |;|&|\||$)" \
  && decide deny "Direct push to main/master. Ticket work reaches it only through a PR that Yash approves."
if has "$GIT +push *($|;|&|\|)|$GIT +push +(-u +)?origin *($|;|&|\|)"; then
  dir=$(grep -oE -- '-C +[^ ]+' <<<"$cmd" | head -1 | awk '{print $2}')
  cur=$(git -C "${dir:-$(jq -r '.cwd' <<<"$input")}" branch --show-current 2>/dev/null)
  case $cur in main|master) decide deny "This checkout is on $cur; a bare push would go straight to it." ;; esac
fi
has "$GIT +tag +(-[a-z]+ +)*qa-|$GIT +push [^;&|]* (refs/tags/)?qa-" \
  && decide deny "qa-* tags start the TestFlight and Firebase builds. Yash pushes those, or says so explicitly."
has '(^|[ ;&|])(npx +)?eas +(build|submit|update)|npm +run +build:qa' \
  && decide deny "EAS build/submit/update needs Yash's explicit approval (AGENTS.md human approval gates)."
has '(^|[ ;&|])(npx +)?firebase +deploy|npm +run +deploy' \
  && decide deny "Firebase deploys target renit-production by default and need Yash's explicit approval."
has '(^|[ ;&|])gh +pr +merge' \
  && decide ask "Merging is Yash's call: approve to merge this PR."
has '(^|[ ;&|])gh +workflow +run' \
  && decide ask "A manual workflow run can start a TestFlight or Firebase build. Approve to start it."
exit 0
