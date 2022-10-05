#!/usr/bin/env bash
# Bluetooth info

has_headset() {
    if ! command -v bluetoothctl &> /dev/null; then
        false
        return
    fi
    if [[ ! -e /sys/class/bluetooth ]]; then
        false
        return
    fi
    local bt_summary
    bt_summary="$(bluetoothctl -- list)"
    local num_devices
    num_devices=$(echo "${bt_summary}" | grep -Poc "Controller [0-9A-F]{2}(:[0-9A-f]{2}){5} .+ \[default\]")
    [[ ${num_devices} -gt 0 ]]
}

headset() {
  local device
  device="04:5D:4B:97:5D:55"
  local bt_device_info
  bt_device_info="$(bluetoothctl -- info "${device}")"
  local name
  # shellcheck disable=SC2312
  name="$(echo "${bt_device_info}" | grep "Name" | cut -d ":" -f 2 | tr -d '[:space:]')"
  local connected
  # shellcheck disable=SC2312
  connected="$(echo "${bt_device_info}" | grep "Connected" | cut -d ":" -f 2 | tr -d '[:space:]')"
  if [[ "${connected}" != 'yes' ]]; then
    name="-"
  fi
  echo -e " ${name}"
}

