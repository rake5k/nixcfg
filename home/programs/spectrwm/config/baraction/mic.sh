#!/usr/bin/env bash
# Microphone volume indicator

mic() {
  local capture_summary
  capture_summary="$(amixer get Capture)"
  local capture_state
  capture_state=$(echo "${capture_summary}" | awk -F'[][]' 'END{ print $4":"$2 }')
  local capture_volume
  capture_volume="${capture_state//on:/}"
  echo -e " ${capture_volume}"
}

