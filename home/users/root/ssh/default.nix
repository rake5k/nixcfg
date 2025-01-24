{ config, lib, ... }:

let

  cfg = config.custom.users.root.ssh;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.users.root.ssh = {
      enable = mkEnableOption "SSH";
    };
  };

  config = mkIf cfg.enable {

    programs.ssh = {
      enable = true;
      matchBlocks = {
        "code.harke.ch" = {
          identityFile = "/etc/ssh/ssh_host_ed25519_key";
        };
      };
    };
  };
}
