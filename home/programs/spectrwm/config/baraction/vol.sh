#!/usr/bin/env bash
# Volume indicator

vol() {
  local master_summary
  master_summary="$(amixer get Master)"
  local master_state
  master_state="$(echo "${master_summary}" | awk -F'[][]' 'END{ print $4":"$2 }')"
  local master_volume
  master_volume="${master_state//on:/}"
  echo -e "墳${master_volume}"
}

