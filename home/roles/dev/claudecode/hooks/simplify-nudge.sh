#!/usr/bin/env bash
# `record` (PostToolUse on file edits) logs each edited project file; `stop` (Stop) blocks the
# stop once SIMPLIFY_NUDGE_EDITS edits piled up and asks Claude to run the `simplify` skill.
# The stop after that pass is let through and resets the log, so simplify's own edits never re-arm it.
set -euo pipefail

input=$(cat)
session=$(jq -r .session_id <<<"${input}")
state="${XDG_RUNTIME_DIR:-/tmp}/claude-simplify-nudge/${session}"
edits="${state}/edits"
pending="${state}/pending"
mkdir -p "${state}"

case "$1" in
record)
  file=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"${input}")
  cwd=$(jq -r .cwd <<<"${input}")
  if [[ ${file} == "${cwd}"/* ]]; then
    printf '%s\n' "${file}" >>"${edits}"
  fi
  ;;
stop)
  if [[ -e ${pending} ]]; then
    rm -f "${pending}" "${edits}"
    exit 0
  fi
  [[ -s ${edits} ]] || exit 0
  count=$(wc -l <"${edits}")
  ((count >= ${SIMPLIFY_NUDGE_EDITS:-10})) || exit 0
  files=$(sort -u "${edits}")
  touch "${pending}"
  jq -n --arg files "${files}" '{
    decision: "block",
    reason: ("Files edited since the last simplify pass:\n" + $files
      + "\nRun the `simplify` skill on these changes, re-verify, then finish.")
  }'
  ;;
*)
  echo "usage: $0 record|stop" >&2
  exit 1
  ;;
esac
