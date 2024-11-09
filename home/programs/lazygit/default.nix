{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.programs.lazygit;

in

{
  options = {
    custom.programs.lazygit = {
      enable = mkEnableOption "Lazygit";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [ lazygit ];

      shellAliases = {
        lg = "lazygit";
      };
    };

    xdg.configFile."jesseduffield/lazygit/config.yml" = mkIf cfg.enable {
      text = ''
        reporting: "off"
      '';
    };
  };
}
