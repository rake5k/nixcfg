{ config, lib, pkgs, rootPath, ... }:

with lib;

let

  cfg = config.custom.base.non-nixos;

  flakeBaseDir = config.home.homeDirectory + "/.nix-config";

in

{

  options = {
    custom.base.non-nixos = {
      enable = mkEnableOption "Config for non NixOS systems";

      installNix = mkEnableOption "Nix installation" // { default = true; };
    };
  };

  config = mkIf cfg.enable {

    home = {
      packages = with pkgs; [
        unstable.home-manager
        nixStatic
      ];

      shellAliases = {
        hm-switch = "home-manager switch -b hm-bak --flake '${flakeBaseDir}'";
      };
    };

    programs.zsh.envExtra = mkAfter ''
      hash -f
    '';

    targets.genericLinux.enable = true;

    xdg.configFile."nix/nix.conf".text = ''
      experimental-features = nix-command flakes
    '';
  };
}
