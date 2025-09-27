# shellcheck disable=SC1091,SC2148
source @bashLib@

# Source: https://qfpl.io/posts/installing-nixos/

### Gather system info

readonly HOSTNAME="${1}"
readonly FLAKE="${2}"

# Validate arguments

test "${HOSTNAME}" || {
  # shellcheck disable=SC2016
  echo '$HOSTNAME is not given!'
  exit 1
}

test "${FLAKE}" || {
  # shellcheck disable=SC2016
  echo '$FLAKE is not given!'
  exit 1
}

# Define functions

generate_initrd_ssh_host_keys() {
  root_dir="/mnt/disko-install-root"
  secrets_dir="${root_dir}/etc/secrets/initrd"
  mkdir -p "${secrets_dir}"
  ssh-keygen -t ed25519 -N "" -f "${secrets_dir}/ssh_host_ed25519_key"
}

### Pull the trigger

# shellcheck disable=SC2310
if _read_boolean "Do you want to DELETE ALL PARTITIONS and INSTALL NixOS now?" N; then
  generate_initrd_ssh_host_keys

  nix run nixpkgs#disko -- --mode disko --flake "${FLAKE}#${HOSTNAME}"
  nixos-install --no-channel-copy --no-root-password --flake "${FLAKE}#${HOSTNAME}"
fi
