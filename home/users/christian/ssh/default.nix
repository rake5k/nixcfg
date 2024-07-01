{ config, lib, pkgs, ... }:

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
    programs.ssh = {
      enable = true;
      controlMaster = "auto";
      controlPath = "~/.ssh/master-%r@%n:%p";
      controlPersist = "10m";
    };
  };
}
