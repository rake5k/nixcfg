{
  config,
  lib,
  pkgs,
  ...
}:

let

  inherit (lib)
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    readFile
    ;

  cfg = config.custom.base.system.btrfs.impermanence;

in

{
  options = {
    custom.base.system.btrfs.impermanence = {
      enable = mkEnableOption "Enable impermanence using BTRFS snapshots";

      extraDirectories = mkOption {
        default = [ ];
        example = literalExpression ''["/var/lib/libvirt"]'';
        description = ''
          Additional directories in the root to link to persistent
          storage.
        '';
      };

      extraFiles = mkOption {
        default = [ ];
        example = literalExpression ''["/etc/nix/id_rsa"]'';
        description = ''
          Additional files in the root to link to persistent storage.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    security.sudo.extraConfig = ''
      # rollback results in sudo lectures after each reboot
      Defaults lecture = never
    '';

    programs.fuse.userAllowOther = true;

    # This script does the actual wipe of the system
    # So if it doesn't run, the btrfs system effectively acts like a normal system
    # Taken from https://github.com/NotAShelf/nyx/blob/2a8273ed3f11a4b4ca027a68405d9eb35eba567b/modules/core/common/system/impermanence/default.nix
    boot.initrd.systemd = {
      enable = true;
      services.rollback = {
        description = "Rollback BTRFS root subvolume to a pristine state";
        wantedBy = [ "initrd.target" ];
        # make sure it's done after encryption
        # i.e. LUKS/TPM process
        after = [ "systemd-cryptsetup@cryptroot.service" ];
        # mount the root fs before clearing
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
          mkdir -p /mnt

          # We first mount the btrfs root to /mnt
          # so we can manipulate btrfs subvolumes.
          mount -o subvol=/ /dev/mapper/cryptroot /mnt
          btrfs subvolume list -o /mnt/root

          # While we're tempted to just delete /root and create
          # a new snapshot from /root-blank, /root is already
          # populated at this point with a number of subvolumes,
          # which makes `btrfs subvolume delete` fail.
          # So, we remove them first.
          #
          # /root contains subvolumes:
          # - /root/var/lib/portables
          # - /root/var/lib/machines

          btrfs subvolume list -o /mnt/root |
          cut -f9 -d' ' |
          while read subvolume; do
            echo "deleting /$subvolume subvolume..."
            btrfs subvolume delete "/mnt/$subvolume"
          done &&
          echo "deleting /root subvolume..." &&
          btrfs subvolume delete /mnt/root

          echo "restoring blank /root subvolume..."
          btrfs subvolume snapshot /mnt/root-blank /mnt/root

          # Once we're done rolling back to a blank snapshot,
          # we can unmount /mnt and continue on the boot process.
          umount /mnt
        '';
      };
    };

    environment = {
      persistence."/persist" = {
        hideMounts = true;
        directories = [
          "/etc/NetworkManager/system-connections"
          "/etc/secureboot"
          "/var/cache/"
          "/var/db/sudo/"
          "/var/lib/"
        ] ++ cfg.extraDirectories;
        files = [
          "/etc/machine-id"
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
          "/etc/ssh/ssh_host_rsa_key"
          "/etc/ssh/ssh_host_rsa_key.pub"
          "/etc/secrets/initrd/ssh_host_ed25519_key"
          "/etc/secrets/initrd/ssh_host_ed25519_key.pub"
        ] ++ cfg.extraFiles;
      };

      systemPackages = with pkgs; [
        (writeShellApplication {
          name = "fs-diff";
          runtimeInputs = [
            coreutils
            gnused
            btrfs-progs
          ];
          text = readFile ./fs-diff.sh;
        })
        (writeShellApplication {
          name = "root-diff";
          runtimeInputs = [
            coreutils
            gnused
            btrfs-progs
          ];
          text = ''
            sudo mkdir -p /mnt
            sudo mount -o subvol=/ /dev/mapper/cryptroot /mnt
            fs-diff
            sudo umount /mnt
          '';
        })
      ];
    };

    fileSystems."/persist".neededForBoot = true;
  };
}
