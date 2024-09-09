{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.containers;

in

{
  options = {
    custom.roles.containers = {
      enable = mkEnableOption "Container tooling";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      dive
      skopeo
    ];

    programs.k9s.enable = true;
  };
}
