#!/usr/bin/env bash
# shellcheck disable=SC2312
# baraction.sh for spectrwm status bar

for i in "$(dirname "$0")"/baraction/*; do
    # shellcheck source=/dev/null
    source "${i}"
done

# Loops forever outputting a line every SLEEP_SEC secs
SLEEP_SEC=1

HAS_TEMP=has_temp
HAS_WIFI=has_wifi
HAS_HEADSET=has_headset
HAS_BATT=has_batt

render() {
    local template
    template="$(cpu) · $(mem) · $(hdd)"
    if ${HAS_TEMP}; then template="${template} · $(temp)"; fi
    if ${HAS_WIFI}; then template="${template} · $(wifi)"; fi
    if ${HAS_HEADSET}; then template="${template} · $(headset)"; fi
    template="${template} · $(vol) · $(mic)"
    if ${HAS_BATT}; then template="${template} · $(batt)"; fi
    template="${template} · $(datetime)"
    echo "${template}"
}

# It seems that we are limited to how many characters can be displayed via
# the baraction script output. And the the markup tags count in that limit.
while :; do
    render
    sleep "${SLEEP_SEC}"
done
