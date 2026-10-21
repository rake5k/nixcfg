{
  config,
  lib,
  pkgs,
  ...
}@args:

with lib;

let

  desktopCfg = config.custom.roles.desktop;
  cfg = desktopCfg.passwordManager;

  # Set only when home-manager runs as a NixOS module; reusing its package
  # (polkit override included) keeps a single 1Password store path.
  nixos1Password = args.osConfig.programs._1password-gui or { enable = false; };

in

{
  options = {
    custom.roles.desktop.passwordManager = {
      enable = mkEnableOption "Password manager";

      package = mkOption {
        type = types.package;
        default = if nixos1Password.enable then nixos1Password.package else pkgs._1password-gui;
        defaultText = literalExpression "osConfig.programs._1password-gui.package or pkgs._1password-gui";
        description = "Password manager package";
      };

      spawnCmd = mkOption {
        type = types.str;
        default = "1password";
        description = "Command to spawn the password manager";
      };
    };
  };

  config = mkIf cfg.enable { home.packages = [ cfg.package ]; };
}
