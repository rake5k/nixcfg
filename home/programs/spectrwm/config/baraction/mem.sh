#!/usr/bin/env bash
## RAM usage indicator

mem() {
  local memory_summary
  memory_summary="$(free)"
  local memory_usage
  memory_usage=$(echo "${memory_summary}" | awk '/Mem/ {printf "%d%\n", $3 / $2 * 100 }')
  echo -e "  ${memory_usage}"
}

