{ config, lib, ... }:

let

  cfg = config.custom.users.christian.ssh;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.users.christian.ssh = {
      enable = mkEnableOption "Secure shell configuration";
    };
  };

  config = mkIf cfg.enable {
    custom.roles.ssh.enable = true;
  };
}
