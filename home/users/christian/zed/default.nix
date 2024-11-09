{ config, lib, ... }:

with lib;

let

  cfg = config.custom.users.christian.zed;

in

{
  options = {
    custom.users.christian.zed = {
      enable = mkEnableOption "Zed editor config";
    };
  };

  config = mkIf cfg.enable {
    programs.zed-editor.enable = true;
  };
}
