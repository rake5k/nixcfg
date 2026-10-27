#!/usr/bin/env bash
# SessionStart hook: inject a budgeted view of the wiki's hub routing index (the L2 "page table"):
# every page name grouped by hub, plus the full routing lines of pages matching the current repo.
# Never page bodies. See llm-wiki's SKILL.md for the L1/L2 model.
# Stdout of a SessionStart hook is added to the session context, capped by Claude Code at 10,000
# characters (https://code.claude.com/docs/en/hooks); the overflow only reaches Claude as a preview.
set -euo pipefail

root="${LLM_WIKI_ROOT:-${HOME}/Documents/notes/claude}"
config="${root}/llm-wiki.yml"
[[ -r ${config} ]] || exit 0

pages_dir=$(sed -n 's/^pages_dir:[[:space:]]*//p' "${config}")
pages="${root}/${pages_dir:-pages}"
[[ -d ${pages} ]] || exit 0

max_chars="${LLM_WIKI_INDEX_MAX_CHARS:-9500}"

# Hub pages are the only ones carrying `### Index`, so scanning every page covers both the
# logseq (flat Wiki___*.md) and obsidian (Wiki/**.md) layouts. `### Archive` ends the live block.
# Syncthing conflict copies keep the .md suffix, so skip them or a stale hub page's routing
# lines get injected a second time.
index=$(find "${pages}" -type f -name '*.md' ! -name '*.sync-conflict-*' -print0 | sort -z | xargs -0 --no-run-if-empty awk '
  FNR == 1                       { in_index = 0 }
  /###[[:space:]]+Index/         { in_index = 1; next }
  in_index && /###[[:space:]]+/  { in_index = 0 }
  in_index && /^[[:space:]]*-?[[:space:]]*\[\[/ { sub(/^[[:space:]]*-?[[:space:]]*/, "- "); print }
')
[[ -n ${index} ]] || exit 0

# One line per hub: page count, then the page names with -Architecture/-Operations/-Testing
# variants merged ($1 = 1), or the page count alone ($1 = 0) when the names overflow.
hubs() {
  sed -E 's/^- \[\[([^]]*)\]\].*/\1/' <<<"${index}" | awk -F/ -v names="$1" '
    {
      hub = $2; name = substr($0, length($1) + length($2) + 3)
      sub(/-(Architecture|Operations|Testing)$/, "", name)
      if (!(hub in count)) order[++hubs] = hub
      count[hub]++
      if (!seen[hub SUBSEP name]++) list[hub] = list[hub] (list[hub] == "" ? "" : ", ") name
    }
    END {
      for (i = 1; i <= hubs; i++) {
        hub = order[i]
        printf "- %s (%d pages)%s\n", hub, count[hub], names ? ": " list[hub] : ""
      }
    }'
}

# The repo's name (the main checkout's, also from inside a worktree) keys the full routing lines.
project_dir="${CLAUDE_PROJECT_DIR:-${PWD}}"
common_dir=$(git -C "${project_dir}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
repo_dir="${common_dir%/.git}"
project=$(basename "${repo_dir:-${project_dir}}")
key=$(tr -cd '[:alnum:]' <<<"${project,,}")
relevant=""
if ((${#key} >= 3)); then
  relevant=$(awk -v key="${key}" '{ line = tolower($0); gsub(/[^a-z0-9]/, "", line) } index(line, key)' <<<"${index}")
fi

# Capture queue: dated lines under `## Pending` in the inbox page, awaiting `/wiki ingest inbox`.
inbox=$(find "${pages}" -type f -name '*Ingest-Inbox*' ! -name '*.sync-conflict-*' -print -quit)
pending=0
if [[ -n ${inbox} ]]; then
  pending=$(grep -cE '^[[:space:]]*-[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+--' "${inbox}" || true)
fi
footer=""
if ((pending > 0)); then
  footer="Capture queue: ${pending} learning(s) pending in [[Wiki/Reference/Ingest-Inbox]]. Offer \`/wiki ingest inbox\` once the current task is finished — not mid-task."
fi

header="Wiki (L2) routing index for the hub pages under ${pages}: every page name per hub, and the
full routing lines (\`[[page]] -- description #tags\`) of the pages matching this repo. A hub's
\`### Index\` holds the routing lines of all its pages. Page bodies are not loaded.

Before searching the web or grepping a repo for my projects, business processes, decisions or
infra, check whether a page name below covers the question. If one does, answer via
\`/wiki query <question>\` (reads the hub index and at most 3 full pages, logs the hit) instead
of external sources."

overview="Pages per hub:"$'\n'"$(hubs 1)"
if ((${#header} + ${#overview} + ${#footer} + 4 > max_chars)); then
  overview="Pages per hub (names omitted: over the ${max_chars}-char budget):"$'\n'"$(hubs 0)"
fi

# Full routing lines fill what the budget leaves, in index order.
section=""
if [[ -n ${relevant} ]]; then
  title="Routing lines matching \`${project}\`:"
  room=$((max_chars - ${#header} - ${#overview} - ${#footer} - ${#title} - 100))
  shown=0 total=0
  while IFS= read -r line; do
    total=$((total + 1))
    if ((${#section} + ${#line} + 1 <= room)); then
      section+=$'\n'"${line}"
      shown=$((shown + 1))
    fi
  done <<<"${relevant}"
  ((shown == total)) || section+=$'\n'"- (+$((total - shown)) matching routing lines omitted — read the hub's \`### Index\`)"
  section="${title}${section}"
fi

printf '%s\n\n%s\n' "${header}" "${overview}"
for part in "${section}" "${footer}"; do
  [[ -z ${part} ]] || printf '\n%s\n' "${part}"
done
