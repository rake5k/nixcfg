#!/usr/bin/env bash
# Battery power indicator

get_batt_summary() {
    acpi -b 2> /dev/null
}

has_batt() {
    if ! command -v acpi &> /dev/null; then
        false
        return
    fi
    if [[ ! -e /sys/class/power_supply ]]; then
        false
        return
    fi
    local battery_summary
    battery_summary="$(get_batt_summary)"
    local battery_count
    battery_count=$(echo "${battery_summary}" | grep -c "Battery")
    [[ ${battery_count} -gt 0 ]]
}

batt() {
    local battery_summary
    battery_summary="$(get_batt_summary)"
    local battery_one
    battery_one="$(echo "${battery_summary}" | head -n 1)"
    local battery_percentage
    battery_percentage="$(echo "${battery_one}" | grep -Po "[[:digit:]]{1,3}%")"
    echo -e " ${battery_percentage}"
}

