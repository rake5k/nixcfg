#!/usr/bin/env bash
# SessionStart hook: inject the wiki's hub routing index (the L2 "page table") into context, so
# routing to a wiki page happens without an explicit /wiki query. Emits only the `### Index`
# routing lines from hub pages — never page bodies. See commands/wiki.md for the L1/L2 model.
# Stdout of a SessionStart hook is added to the session context.
set -euo pipefail

root="${LLM_WIKI_ROOT:-${HOME}/Documents/notes/claude}"
config="${root}/llm-wiki.yml"
[[ -r ${config} ]] || exit 0

pages_dir=$(sed -n 's/^pages_dir:[[:space:]]*//p' "${config}")
pages="${root}/${pages_dir:-pages}"
[[ -d ${pages} ]] || exit 0

# Hub pages are the only ones carrying `### Index`, so scanning every page covers both the
# logseq (flat Wiki___*.md) and obsidian (Wiki/**.md) layouts. `### Archive` ends the live block.
index=$(find "${pages}" -type f -name '*.md' -print0 | xargs -0 --no-run-if-empty awk '
  FNR == 1                       { in_index = 0 }
  /###[[:space:]]+Index/         { in_index = 1; next }
  in_index && /###[[:space:]]+/  { in_index = 0 }
  in_index && /^[[:space:]]*-?[[:space:]]*\[\[/ { sub(/^[[:space:]]*-?[[:space:]]*/, "- "); print }
')
[[ -n ${index} ]] || exit 0

max_lines="${LLM_WIKI_INDEX_MAX_LINES:-150}"
total=$(grep -c '' <<<"${index}")
if ((total > max_lines)); then
  omitted=$((total - max_lines))
  index=$(head -n "${max_lines}" <<<"${index}")$'\n'"- (+${omitted} routing lines omitted — run \`/wiki status\`)"
fi

# Capture queue: dated lines under `## Pending` in the inbox page, awaiting `/wiki ingest inbox`.
inbox=$(find "${pages}" -type f -name '*Ingest-Inbox*' -print -quit)
pending=0
if [[ -n ${inbox} ]]; then
  pending=$(grep -cE '^[[:space:]]*-[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+--' "${inbox}" || true)
fi

cat <<EOF
Wiki (L2) routing index — the live \`### Index\` lines of every hub page under ${pages}.
Format: [[page]] -- description #tags. This is the index only; page bodies are not loaded.

Before searching the web or grepping a repo for my projects, business processes, decisions or
infra, check whether a routing line below covers the question. If one does, answer via
\`/wiki query <question>\` (reads at most 3 full pages, logs the hit) instead of external sources.

${index}
EOF

if ((pending > 0)); then
  printf '\n%s\n' "Capture queue: ${pending} learning(s) pending in [[Wiki/Reference/Ingest-Inbox]]. Offer \`/wiki ingest inbox\` once the current task is finished — not mid-task."
fi
