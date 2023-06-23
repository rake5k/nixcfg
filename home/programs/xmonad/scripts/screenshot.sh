#!/usr/bin/env bash

notify_success() {
  notify-send -u low "${1}" "${2}"
}

notify_failure() {
  notify-send -u critical "Taking screenshot failed" "${1}"
}

screenshot() {
  OUT="${HOME}/Pictures/screenshots/%F_%H-%M-%S.png"
  CMD='scrot -z'
  case $1 in
  full)
    # shellcheck disable=SC2016
    FILE="$(${CMD} -m --exec 'echo $f' "${OUT}")" \
      && notify_success "Fullscreen screenshot saved" "${FILE}" \
      || notify_failure "Fullscreen screenshot failed"
  ;;
  select)
    sleep 0.5
    # shellcheck disable=SC2016
    FILE="$(${CMD} -fs --line style=dash,width=2,color="yellow" --exec 'echo $f' "${OUT}")" \
      && notify_success "Selection screenshot saved" "${FILE}" \
      || notify_failure "Selection screenshot aborted"
  ;;
  window)
    # shellcheck disable=SC2016
    FILE="$(${CMD} -u --exec 'echo $f' "${OUT}")" \
      && notify_success "Window screenshot saved" "${FILE}" \
      || notify_failure "Window screenshot failed"
  ;;
  *)
    notify_failure "Taking screenshot failed" "An invalid argument has been passed: '${1}'. Valid values are: 'full', 'select', 'window'"
  esac;
}

screenshot "${1}"
