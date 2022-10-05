#!/usr/bin/env bash

notification() {
    notify-send -u low "${1}" "${2}"
}

screenshot() {
    OUT="${HOME}/Pictures/screenshots/%F_%H-%M-%S.png"
	case $1 in
	full)
        # shellcheck disable=SC2016
        FILE=$(scrot -m "${OUT}" -e 'echo $f')
        notification "Fullscreen screenshot saved" "${FILE}"
		;;
	window)
		sleep 0.5
        # shellcheck disable=SC2016
        FILE=$(scrot -s "${OUT}" -e 'echo $f')
        notification "Current window screenshot saved" "${FILE}"
		;;
    *)
        notify-send -u critical "Taking screenshot failed" "An invalid argument has been passed: '${1}'. Valid values are: 'full', 'window'"
	esac;
}

screenshot "${1}"
