{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.web.messengers;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.roles.web.messengers = {
      enable = mkEnableOption "Messengers";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      element-desktop
      threema-desktop
      (writeShellApplication {
        name = "element-private";
        runtimeInputs = [ element-desktop ];
        text = "element-desktop";
      })
      (writeShellApplication {
        name = "element-public";
        runtimeInputs = [ element-desktop ];
        text = "element-desktop --profile matrix";
      })
    ];
  };
}
