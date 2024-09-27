#!/usr/bin/env bash

set -uo pipefail

notify_success() {
  notify-send -u low "${1}" "${2}"
}

notify_failure() {
  notify-send -u critical "Taking screenshot failed" "${1}"
}

screenshot() {
  OUTDIR="${HOME}/Pictures/screenshots"
  OUT="${OUTDIR}/%F_%H-%M-%S.png"
  CMD='scrot -z'

  mkdir -p "${OUTDIR}"

  case $1 in
  full)
    # shellcheck disable=SC2016
    FILE="$(${CMD} -m --exec 'echo $f' "${OUT}")"
    if [[ -n "${FILE}" ]]
    then
        notify_success "Fullscreen screenshot saved" "${FILE}"
    else
      notify_failure "Fullscreen screenshot failed"
    fi
  ;;
  select)
    sleep 0.5
    # shellcheck disable=SC2016
    FILE="$(${CMD} -fs --line style=dash,width=2,color="yellow" --exec 'echo $f' "${OUT}")"
    if [[ -n "${FILE}" ]]
    then
      notify_success "Selection screenshot saved" "${FILE}"
    else
      notify_failure "Selection screenshot aborted"
    fi
  ;;
  window)
    # shellcheck disable=SC2016
    FILE="$(${CMD} -u --exec 'echo $f' "${OUT}")"
    if [[ -n "${FILE}" ]]
    then
      notify_success "Window screenshot saved" "${FILE}"
    else
      notify_failure "Window screenshot failed"
    fi
  ;;
  *)
    notify_failure "Taking screenshot failed" "An invalid argument has been passed: '${1}'. Valid values are: 'full', 'select', 'window'"
  esac;
}

screenshot "${1}"
