#!/bin/sh
d="/Users/nicolas/Desktop/ai-trader/skill-observations"
open=$(find "$d/observation-log" -maxdepth 1 -name '*.md' -exec grep -l '^status: open$' {} + 2>/dev/null | wc -l | tr -d ' ')
last=$(cat "$d/last-review-date.txt" 2>/dev/null || echo never)
msg="Invoke the task-observer skill AND run its Session Start Protocol before the first tool call or before drafting a plan. Loading the file is not activation. After each task, report the observation ids written this session, or 'none logged and why'."
if [ "${open:-0}" -gt 0 ] 2>/dev/null; then
  msg="$msg ${open} open observations; last review: ${last}."
  [ "$last" = never ] && msg="$msg Offer the review."
fi
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$msg"
