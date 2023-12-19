{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.containers;

in

{
  options = {
    custom.roles.containers = {
      enable = mkEnableOption "Container runtime and tooling";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      dive
      docker-client
      skopeo
    ];
  };
}
