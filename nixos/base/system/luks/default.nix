{
  config,
  lib,
  pkgs,
  ...
}:

let

  inherit (lib)
    attrNames
    concatStringsSep
    hasAttr
    mkEnableOption
    mkIf
    ;

  cfg = config.custom.base.system.luks;

  mapperDevices = concatStringsSep " " (attrNames config.boot.initrd.luks.devices);

  # Login shell of the initrd SSH session: answers the passphrase prompts so the
  # operator does not have to know about systemd-tty-ask-password-agent, then
  # exits 0 once every device is open. Without that exit the session hangs until
  # switch-root kills sshd, which surfaces as a connection reset.
  unlock = pkgs.writeShellApplication {
    name = "remote-unlock";
    runtimeInputs = [
      config.boot.initrd.systemd.package
      pkgs.coreutils
    ];
    text = ''
      # sshd runs a login shell as `<shell> -c <command>`, so keep that path
      # working: it is the only way to get a debug shell in the initrd.
      if [ $# -gt 0 ]; then
        exec /bin/sh "$@"
      fi

      devices=(${mapperDevices})

      unlocked() {
        local device
        for device in "''${devices[@]}"; do
          [ -e "/dev/mapper/$device" ] || return 1
        done
      }

      # The agent only serves the requests pending when it runs, and the disks
      # are asked for one after the other, so keep polling until all are open.
      while ! unlocked; do
        systemd-tty-ask-password-agent --query || true
        sleep 0.2
      done

      echo "All encrypted devices are open, resuming boot."
    '';
  };

in

{
  options = {
    custom.base.system.luks = {
      enable = mkEnableOption "Enable LUKS disk encyption config" // {
        default = true;
      };

      remoteUnlock = mkEnableOption "Enable remote disk unlocking";
    };
  };

  config = mkIf cfg.enable {
    boot.initrd = mkIf (cfg.remoteUnlock && (hasAttr "christian" config.users.users)) {
      availableKernelModules = [ "r8169" ];
      network = {
        enable = true;
        flushBeforeStage2 = true;
        ssh = {
          enable = true;
          # Use a different port so we won't always have host key conflicts
          port = 2222;
          authorizedKeys = config.users.users.christian.openssh.authorizedKeys.keys;
          # Note that these will probably be unencrypted in our setup, but it's mostly fine
          hostKeys = [
            "/etc/secrets/initrd/ssh_host_ed25519_key"
          ];
        };
      };

      systemd = {
        enable = true;

        # NetworkManager pins networking.useDHCP to false, so nixpkgs derives no
        # DHCP network for the initrd: sshd starts but the link never gets an
        # address. Sorts before the generated 40-<interface>.network, which
        # inherits that DHCP=no, and covers hosts that generate no network file
        # at all.
        network.networks."10-remote-unlock" = {
          matchConfig = {
            Type = "ether";
            Kind = "!*"; # physical interfaces have no kind
          };
          DHCP = "yes";
        };

        storePaths = [ "${unlock}/bin/remote-unlock" ];
        users.root.shell = "${unlock}/bin/remote-unlock";
      };
    };
  };
}
