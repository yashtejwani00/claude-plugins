#!/usr/bin/env bash
# UserPromptSubmit: when the whole prompt is a Jira ticket (key or browse URL,
# optionally after "start / work on / pick up / resume"), start the ticket pipeline.
# A key mentioned inside a longer sentence does not trigger it; use /renit-agentic-dev:renit-ticket for that.
input=$(cat)
case $(jq -r '.cwd // ""' <<<"$input") in */renit/*|*/renit) ;; *) exit 0 ;; esac

key=$(jq -r '.prompt // ""' <<<"$input" | tr -d '\n' | grep -oiE \
  '^[[:space:]]*((start|work on|pick up|resume|ticket)[[:space:]]+)?(https?://[^[:space:]]+/browse/)?ENG-[0-9]+[[:space:]]*$' \
  | grep -oiE 'ENG-[0-9]+' | tr 'a-z' 'A-Z')
[ -n "$key" ] || exit 0

jq -n --arg ctx "The user's whole message is the Jira ticket $key. Invoke the Skill tool with skill=renit-agentic-dev:renit-ticket and args=$key, and run that pipeline end to end." \
  '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}'
