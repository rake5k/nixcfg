# shellcheck disable=SC1091,SC2148
source @bashLib@

# Source: https://qfpl.io/posts/installing-nixos/

### Gather system info

readonly HOSTNAME="${1}"
readonly DISK="${2}"

# Validate arguments

test "${HOSTNAME}" || {
    # shellcheck disable=SC2016
    echo '$HOSTNAME is not given!'
    exit 1
}

NUM_SUPPORTED_DISKS=$(echo "${DISK}" | grep -P "^/dev/(sd[a-z]|nvme[0-9]n[1-9])$" -c)
readonly NUM_SUPPORTED_DISKS

[[ ${NUM_SUPPORTED_DISKS} -gt 0 ]] || {
    # shellcheck disable=SC2016
    echo '$DISK is not of format "/dev/sda" or "/dev/nvme0n1"!'
    exit 1
}

NUM_NVME_DISKS=$(echo "${DISK}" | grep "^/dev/nvme" -c)
readonly NUM_NVME_DISKS

is_nvme_disk() {
    [[ ${NUM_NVME_DISKS} -gt 0 ]]
}

get_partition() {
    if is_nvme_disk; then
        echo "${DISK}p${1}"
    else
        echo "${DISK}${1}"
    fi
}

BOOT_PARTITION="$(get_partition 1)"
readonly BOOT_PARTITION
LVM_PARTITION="$(get_partition 2)"
readonly LVM_PARTITION

get_ram_size() {
    local mem_summary
    mem_summary="$(lsmem --summary=only)"
    local mem_summary_online
    mem_summary_online="$(echo "${mem_summary}" | grep "Total online memory:")"
    local mem_online_size
    mem_online_size="$(echo "${mem_summary_online}" | grep -Po "[0-9]+[kKmMgGtTpPeE]")"
    echo "${mem_online_size}"
}

RAM_SIZE="$(get_ram_size)"
readonly RAM_SIZE


### Declare functions

readonly LVM_PV="nixos-enc"
readonly LVM_VG="nixos-vg"
readonly LVM_LV_ROOT="/dev/${LVM_VG}/root"
readonly LVM_LV_SWAP="/dev/${LVM_VG}/swap"

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

create_volumes() {
    _log "[create_volumes] Encrypting LVM partition..."
    cryptsetup luksFormat "${LVM_PARTITION}"
    cryptsetup luksOpen "${LVM_PARTITION}" "${LVM_PV}"

    _log "[create_volumes] Creating LVM volumes..."
    pvcreate "/dev/mapper/${LVM_PV}"
    vgcreate "${LVM_VG}" "/dev/mapper/${LVM_PV}"
    lvcreate -L "${RAM_SIZE}" -n swap "${LVM_VG}"
    lvcreate -l 100%FREE -n root "${LVM_VG}"
}

create_filesystems() {
    # TODO: Switch to btrfs (https://github.com/wiltaylor/dotfiles/blob/master/tools/makefs-nixos)
    _log "[create_filesystems] Creating filesystems..."
    mkfs.vfat -n boot "${BOOT_PARTITION}"
    mkfs.ext4 -L nixos "${LVM_LV_ROOT}"
    mkswap -L swap "${LVM_LV_SWAP}"

    _log "[create_filesystems] Result of filesystems creation:"
    lsblk -f "${DISK}"
}

decrypt_lvm() {
    _log "[decrypt_lvm] Decrypting volumes..."
    cryptsetup luksOpen "${LVM_PARTITION}" "${LVM_PV}"
    lvscan
    vgchange -ay

    _log "[decrypt_lvm] Volumes decrypted:"
    lsblk -f "${DISK}"
}

install() {
    local mount_root="/mnt"
    local mount_boot="${mount_root}/boot"

    _log "[install] Enabling swap..."
    local swap_list
    swap_list="$(swapon --noheadings)"
    local num_swap
    num_swap=$(echo "${swap_list}" | wc -l)
    if [[ ${num_swap} -lt 1 ]]; then
        swapon -v "${LVM_LV_SWAP}"
    fi

    _log "[install] Mounting volumes..."
    mount "${LVM_LV_ROOT}" "${mount_root}"
    mkdir -p "${mount_boot}"
    mount "${BOOT_PARTITION}" "${mount_boot}"

    _log "[install] Installing NixOS..."
    nixos-install --root "${mount_root}" --flake "github:christianharke/nixcfg#${HOSTNAME}" --impure
    _log "[install] Installing NixOS... finished!"

    _log "[install] Installation finished, please reboot and remove installation media..."
}


### Pull the trigger

if _read_boolean "Do you want to DELETE ALL PARTITIONS?" N; then
    partition
    create_volumes
    create_filesystems
fi

LVM_PV_STATUS="$(cryptsetup -q status "${LVM_PV}")"
readonly LVM_PV_STATUS
LVM_PV_NUM_ACTIVE=$(echo "${LVM_PV_STATUS}" | grep "^/dev/mapper/${LVM_PV} is active and is in use.$" -c)
readonly LVM_PV_NUM_ACTIVE
if [[ ${LVM_PV_NUM_ACTIVE} -lt 1 ]]; then
    decrypt_lvm
fi

if _read_boolean "Do you want to INSTALL NixOS now?" N; then
    install
fi

