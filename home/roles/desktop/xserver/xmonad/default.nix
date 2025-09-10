{
  config,
  lib,
  pkgs,
  ...
}:

let

  desktopCfg = config.custom.roles.desktop;
  xCfg = desktopCfg.xserver;
  cfg = xCfg.xmonad;

  inherit (config.lib.custom) mkWindowManagerOptions;
  inherit (lib) mkIf mkEnableOption;
  inherit (pkgs) callPackage;

  modKey =
    if cfg.modKey == "Super" then
      "mod4"
    else if cfg.modKey == "Alt" then
      "mod4"
    else if cfg.modKey == "Apple" then
      "mod2"
    else
      "mod4";

in

{
  options = {
    custom.roles.desktop.xserver.xmonad = mkWindowManagerOptions "Xmonad" // {
      lightweight = mkEnableOption "Disable resource intensive effects";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      roles.desktop = {
        notification = {
          enable = true;
          offset = "15x40";
        };

        xserver = {
          picom.enable = !cfg.lightweight;

          polybar = {
            enable = true;
            inherit (cfg) colorScheme;
            font = {
              inherit (cfg.font) package;
              config = cfg.font.xft;
            };
            height = 20;
            monitors.battery = cfg.isMobile;
          };
        };
      };
    };

    xsession.windowManager.xmonad = {
      enable = true;
      extraPackages = haskellPackages: [
        haskellPackages.xmonad-contrib
        haskellPackages.xmonad-extras
      ];
      config = callPackage ./xmonad.hs.nix {
        inherit modKey;
        inherit (cfg)
          autoruns
          colorScheme
          passwordManager
          screenshotCfg
          terminalCfg
          volumeCtl
          wiki
          ;
        inherit (cfg.launcherCfg) launcherCmd;
        inherit (cfg.lockerCfg) lockerCmd;
      };
    };
  };
}
