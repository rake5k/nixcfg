#!/usr/bin/env bash
# Temperature indicator

has_temp() {
    sensors &> /dev/null
    return
}

temp() {
  local sensors_json
  sensors_json="$(sensors -j "coretemp-isa-0000")"
  local temp_celsius
  temp_celsius="$(echo "${sensors_json}" | jq '."coretemp-isa-0000"[] | objects | select(has("temp1_input"))."temp1_input"')"
  echo -e " ${temp_celsius}°C"
}

