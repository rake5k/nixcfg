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

(( NUM_SUPPORTED_DISKS > 0 )) || {
    # shellcheck disable=SC2016
    echo '$DISK is not of format "/dev/sda" or "/dev/nvme0n1"!'
    exit 1
}

NUM_NVME_DISKS=$(echo "${DISK}" | grep "^/dev/nvme" -c || true)
readonly NUM_NVME_DISKS

is_nvme_disk() {
    (( NUM_NVME_DISKS > 0 ))
}

get_partition() {
    # shellcheck disable=SC2310
    if is_nvme_disk; then
        echo "${DISK}p${1}"
    else
        echo "${DISK}${1}"
    fi
}

BOOT_PARTITION="$(get_partition 1)"
readonly BOOT_PARTITION
ROOT_PARTITION="$(get_partition 2)"
readonly ROOT_PARTITION


### Declare functions

readonly ROOT_CRYPT="root-crypt"
readonly BOOT_FS="BOOT"
readonly ROOT_FS="root"
readonly MOUNT_ROOT="/mnt"

partition() {
    _log "[partition] Deleting partitions..."
    dd if=/dev/zero of="${DISK}" bs=512 count=1 conv=notrunc status=progress

    _log "[partition] Creating partition table..."
    parted "${DISK}" mklabel gpt
    parted "${DISK}" mkpart "boot" fat32 0% 1GiB
    parted "${DISK}" set 1 esp on
    parted "${DISK}" mkpart "root" ext4 1GiB 100%

    _log "[partition] Result of partitioning:"
    fdisk "${DISK}" -l
}

crypt_setup() {
    _log "[crypt_setup] Encrypting LVM partition..."
    cryptsetup luksFormat "${ROOT_PARTITION}"
    cryptsetup luksOpen "${ROOT_PARTITION}" "${ROOT_CRYPT}"
}

create_filesystems() {
    local root_partition="${1}"
    _log "[create_filesystems] Creating filesystems..."
    mkfs.vfat -n "${BOOT_FS}" "${BOOT_PARTITION}"
    mkfs.btrfs -f  -L "${ROOT_FS}" "${root_partition}"

    sleep 2

    _log "[create_filesystems] Creating sub volumes"
    mount "/dev/disk/by-label/${ROOT_FS}" "${MOUNT_ROOT}"
    btrfs subvolume create "${MOUNT_ROOT}/@"
    btrfs subvolume create "${MOUNT_ROOT}/@home"
    btrfs subvolume create "${MOUNT_ROOT}/@nix"
    btrfs subvolume create "${MOUNT_ROOT}/@swap"
    umount "${MOUNT_ROOT}"

    _log "[create_filesystems] Result of filesystems creation:"
    lsblk -f "${DISK}"
}

decrypt_volumes() {
    _log "[decrypt_volumes] Decrypting volumes..."
    cryptsetup luksOpen "${ROOT_PARTITION}" "${ROOT_CRYPT}"

    _log "[decrypt_volumes] Volumes decrypted:"
    lsblk -f "${DISK}"
}

mount_filesystems() {
    _log "[mount_filesystems] Checking if we need to decrypt any disk..."
    ROOT_PARTITION_TYPE=$(blkid -s "TYPE" -o "value" "${ROOT_PARTITION}")
    readonly ROOT_PARTITION_TYPE
    _log "[mount_filesystems] Root partition type is: ${ROOT_PARTITION_TYPE}"
    if [[ "${ROOT_PARTITION_TYPE}" == "crypto_LUKS" ]]; then
        CRYPT_VOL_STATUS="$(cryptsetup -q status "${ROOT_CRYPT}" || true)"
        readonly CRYPT_VOL_STATUS
        _log "[mount_filesystems] Volume encryption status is: ${CRYPT_VOL_STATUS}"
        CRYPT_VOL_NUM_ACTIVE=$(echo "${CRYPT_VOL_STATUS}" | grep "^/dev/mapper/${ROOT_CRYPT} is active.$" -c || true)
        readonly CRYPT_VOL_NUM_ACTIVE
	if (( CRYPT_VOL_NUM_ACTIVE < 1 )); then
            _log "[mount_filesystems] Volume is not active yet, we need to decrypt it."
            decrypt_volumes
        fi
    fi

    sleep 2

    _log "[mount_filesystems] Mounting file systems..."

    grep "${ROOT_PARTITION} ${MOUNT_ROOT} btrfs" "/proc/mounts" \
        || mount -o noatime,compress=lzo,subvol=@ "/dev/disk/by-label/${ROOT_FS}" "${MOUNT_ROOT}"

    # shellcheck disable=SC2248
    mkdir -p ${MOUNT_ROOT}/{home,nix,swap}
    grep "${ROOT_PARTITION} ${MOUNT_ROOT}/home btrfs" "/proc/mounts" \
        || mount -o noatime,compress=lzo,subvol=@home "/dev/disk/by-label/${ROOT_FS}" "${MOUNT_ROOT}/home"
    grep "${ROOT_PARTITION} ${MOUNT_ROOT}/nix btrfs" "/proc/mounts" \
        || mount -o noatime,compress=zstd,subvol=@nix "/dev/disk/by-label/${ROOT_FS}" "${MOUNT_ROOT}/nix"
    grep "${ROOT_PARTITION} ${MOUNT_ROOT}/swap btrfs" "/proc/mounts" \
        || mount -o subvol=@swap "/dev/disk/by-label/${ROOT_FS}" "${MOUNT_ROOT}/swap"

    local mount_boot="${MOUNT_ROOT}/boot"
    mkdir -p "${mount_boot}"
    grep "${BOOT_PARTITION} ${mount_boot} vfat" "/proc/mounts" \
        || mount "${BOOT_PARTITION}" "${mount_boot}"

    _log "[mount_filesystems] File systems mounted:"
    findmnt --real
}

install() {
    _log "[install] Installing NixOS..."
    nixos-install --root "${MOUNT_ROOT}" --flake "${FLAKE}#${HOSTNAME}" --impure
    _log "[install] Installing NixOS... finished!"

    _log "[install] Installation finished, please reboot and remove installation media..."
}


### Pull the trigger

# shellcheck disable=SC2310
if _read_boolean "Do you want to DELETE ALL PARTITIONS?" N; then
    partition

    # shellcheck disable=SC2310
    if _read_boolean "Do you want to ENCRYPT THE DISK?" N; then
        crypt_setup
        create_filesystems "/dev/mapper/${ROOT_CRYPT}"
    else
	create_filesystems "${ROOT_PARTITION}"
    fi

fi

# shellcheck disable=SC2310
if _read_boolean "Do you want to INSTALL NixOS now?" N; then
    mount_filesystems
    install
fi

