#!/usr/bin/env bash
## Wifi signal indicator

INTERFACE="wlp82s0"

has_wifi() {
    [[ -d "/sys/class/net/${INTERFACE}" ]]
}

wifi() {
    local wifi_quality
    # If the wifi interface exists but no connection is active, "down" shall be displayed.
    local iface_state
    iface_state="$(cat "/sys/class/net/${INTERFACE}/operstate")"
    if [[ "${iface_state}" = 'down' ]]; then
        wifi_quality='down'
    fi
    local wifi_summary
    wifi_summary="$(grep "${INTERFACE}" /proc/net/wireless)"
    wifi_quality=$(echo "${wifi_summary}" | awk '{ printf "%d%", int($3 * 100 / 70) }')
    echo -e "直${wifi_quality}"
}

