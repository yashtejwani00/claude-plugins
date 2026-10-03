#!/usr/bin/env bash
# Self-check for guard.sh and ticket-trigger.sh. Run after editing either.
cd "$(dirname "$0")" || exit 1
fail=0
CWD=/Users/zineone/git/renit/rn-app

guard() { # expected-decision, command
  got=$(jq -n --arg c "$2" --arg d "$CWD" '{cwd: $d, tool_input: {command: $c}}' | ./guard.sh | jq -r '.hookSpecificOutput.permissionDecision // "allow"')
  [ "${got:-allow}" = "$1" ] || { echo "FAIL guard: want $1 got ${got:-allow}: $2"; fail=1; }
}
guard deny  'git push origin main'
guard deny  'git -C /x/rn-api push origin HEAD:master'
guard deny  'git push --force origin ENG-1-x:main && echo hi'
guard allow 'git push -u origin ENG-12-Fix-main-screen-crash'
guard allow 'git -C /x/rn-api-eng12 push -u origin ENG-12-master-data-load'
guard deny  'git tag qa-2026-10-04'
guard deny  'git push origin qa-17'
guard allow 'git push -u origin ENG-9-qa-evidence-folder'
guard deny  'npx eas build --profile qa'
guard deny  'cd functions && firebase deploy'
guard ask   'gh pr merge 21 --squash --repo simplyrenit/rn-api'
guard allow 'gh pr create --title "ENG-1: x" --body "merge notes"'
guard allow 'npx tsc --noEmit'
guard deny  'npm run build:qa'
guard deny  'cd functions && npm run deploy'
guard deny  'git push origin refs/heads/main'
guard deny  'git push origin +HEAD:refs/heads/master'
guard deny  'git -C "/Users/zineone/git/renit/rn-api-eng9" push origin master'
guard ask   'gh workflow run testflight-qa.yml --ref main'
guard allow 'gh pr create --title "ENG-1: x" --body "run git push origin main, then gh pr merge"'
guard allow "git commit -m 'ENG-1: stop eas build on merge'"
CWD=/Users/zineone/git/claude-plugins guard deny  'git -C /Users/zineone/git/renit/rn-api-eng9 push origin master'
CWD=/Users/zineone/git/claude-plugins guard allow 'git push origin main'

trigger() { # expected-key-or-empty, prompt
  got=$(jq -n --arg p "$2" --arg d "$CWD" '{cwd: $d, prompt: $p}' | ./ticket-trigger.sh | grep -oE 'ENG-[0-9]+' | head -1)
  [ "$got" = "$1" ] || { echo "FAIL trigger: want '$1' got '$got': $2"; fail=1; }
}
trigger ENG-123 'ENG-123'
trigger ENG-123 '  eng-123 '
trigger ENG-45  'start ENG-45'
trigger ENG-45  'pick up https://simplyrenit.atlassian.net/browse/ENG-45'
trigger ''      'ENG-27 has a bug in the filter sheet, why?'
trigger ''      'what is the status of ENG-27'
CWD=/Users/zineone/git/renit trigger ENG-5 'ENG-5'
CWD=/Users/zineone/git/website trigger '' 'ENG-123'

[ $fail = 0 ] && echo "all hook checks pass"
exit $fail
