{ config, lib, ... }:

with lib;

let

  cfg = config.custom.users.christian.ssh;

in

{
  options = {
    custom.users.christian.ssh = {
      enable = mkEnableOption "Secure shell configuration";
    };
  };

  config = mkIf cfg.enable {
    custom.programs.ssh.enable = true;
  };
}
