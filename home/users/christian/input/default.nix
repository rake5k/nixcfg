{ config, lib, ... }:

let

  cfg = config.custom.users.christian.input;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.users.christian.input = {
      enable = mkEnableOption "Input";
    };
  };

  config = mkIf cfg.enable {
    home.keyboard = {
      layout = "de,de";
      variant = "neo_qwertz,bone";
      options = [
        "grp:rctrl_toggle"
        "grp_led:scroll"
      ];
    };
  };
}
