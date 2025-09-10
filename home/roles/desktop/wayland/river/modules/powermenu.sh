#!/usr/bin/env bash
opts="Shut down\nReboot\nLock"
# shellcheck disable=SC2059
selectedOption=$(printf "${opts}" | fuzzel --dmenu --prompt="Powermenu")
[[ -z "${selectedOption}" ]] && exit

case "${selectedOption}" in
"Shut down") shutdown now ;;
"Reboot") reboot ;;
"Lock") swaylock ;;
*) ;;
esac
