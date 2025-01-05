# shellcheck disable=SC1091,SC2148
source @bashLib@

# Source: https://qfpl.io/posts/installing-nixos/

### Gather system info

readonly HOSTNAME="${1}"
readonly DISK="${2}"
readonly FLAKE="${3}"

# Validate arguments

test "${HOSTNAME}" || {
  # shellcheck disable=SC2016
  echo '$HOSTNAME is not given!'
  exit 1
}

NUM_SUPPORTED_DISKS=$(echo "${DISK}" | grep -P "^/dev/(sd[a-z]|nvme[0-9]n[1-9])$" -c || true)
readonly NUM_SUPPORTED_DISKS

((NUM_SUPPORTED_DISKS > 0)) || {
  # shellcheck disable=SC2016
  echo '$DISK is not of format "/dev/sda" or "/dev/nvme0n1"!'
  exit 1
}

### Pull the trigger

# shellcheck disable=SC2310
if _read_boolean "Do you want to DELETE ALL PARTITIONS and INSTALL NixOS now?" N; then
  serial=$(udevadm info --query=property --property=ID_SERIAL_SHORT --value -n "${DISK}")
  symlinks=$(udevadm info --query=property --property=DEVLINKS --value -n "${DISK}")
  device=$(echo "${symlinks}" | awk '{for(i=1;i<=NF;i++) if($i ~ /\/dev\/disk\/by-id\/.*'"${serial}"'$/) {print $i; exit}}')
  [[ -L "${device}" ]] || {
    echo "Could not find a suitable symlink by id for ${DISK}!"
    exit 1
  }

  nix run 'github:nix-community/disko/latest#disko-install' -- --flake "${FLAKE}#${HOSTNAME}" --write-efi-boot-entries --disk "root" "${device}"
fi
