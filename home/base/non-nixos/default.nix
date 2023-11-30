{ config, lib, pkgs, ... }:

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
      activation.report-changes = config.lib.dag.entryAnywhere ''
        ${getExe pkgs.nix} store diff-closures $oldGenPath $newGenPath || true
      '';

      packages = with pkgs; [
        unstable.home-manager
      ];

      shellAliases = {
        hm-switch = "home-manager switch -b hm-bak --impure --flake '${flakeBaseDir}'";
        hm-diff = "home-manager generations | head -n 2 | cut -d' ' -f 7 | tac | xargs ${getExe pkgs.nix} store diff-closures";
      };
    };

    nix = {
      package = mkForce pkgs.nix;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
    };

    programs.zsh.envExtra = mkAfter ''
      hash -f
    '';

    targets.genericLinux.enable = true;
  };
}
