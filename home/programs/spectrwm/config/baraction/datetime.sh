#!/usr/bin/env bash
## Date and time info

datetime() {
  datetime="$(LC_TIME=en_US.UTF-8 date '+%a %b %-d %H:%M')"
  echo -e "  ${datetime}"
}

