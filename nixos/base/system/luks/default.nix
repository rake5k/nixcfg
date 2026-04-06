{ config, lib, ... }:

let

  inherit (lib) hasAttr mkEnableOption mkIf;

  cfg = config.custom.base.system.luks;

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

      systemd.enable = true;
    };
  };
}
