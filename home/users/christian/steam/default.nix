{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.users.christian.steam;

  mkCfgs = filename:
    let
      userId = "5051778";
      appIds = {
        csgo = "730";
      };
      csgoCfgPath = "Steam/steamapps/common/Counter-Strike Global Offensive/game/csgo/cfg";
    in
    nameValuePair "${csgoCfgPath}/${filename}.cfg" {
      source = ./data/${filename}.cfg;
    };

in

{
  options = {
    custom.users.christian.steam = {
      enable = mkEnableOption "Steam config";
    };
  };

  config = mkIf cfg.enable {
    xdg.dataFile = listToAttrs (map mkCfgs [
      "autoexec"
      "binds"
      "crosshair"
      "hud"
      "input"
      "myconf"
      "net"
    ]
    );
  };
}
