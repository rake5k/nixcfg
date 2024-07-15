{ config, lib, ... }:

with lib;

let

  cfg = config.custom.users.christian.steam;

  mkCfgs = filename:
    let
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
