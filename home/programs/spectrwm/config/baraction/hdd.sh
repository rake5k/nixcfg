#!/usr/bin/env bash
## Available disk space indicator

hdd() {
  local disk_free_root
  disk_free_root="$(df -hPl "/")"
  local disk_usage_percentage
  disk_usage_percentage="$(echo "${disk_free_root}" | awk 'NR==2{print $4}')"
  echo -e "  ${disk_usage_percentage}"
}

