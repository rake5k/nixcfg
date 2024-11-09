{
  lib,
  config,
  pkgs,
  ...
}:

let

  cfg = config.custom.base.non-nixos.home-manager;
  flakeBaseDir = config.home.homeDirectory + "/.nix-config";

in

{
  options = {
    custom.base.non-nixos.home-manager = {
      enable = lib.mkEnableOption "Config for non NixOS systems";
    };
  };

  config = lib.mkIf cfg.enable {

    home = {
      packages = with pkgs; [ home-manager ];

      shellAliases = {
        hm-switch = "home-manager switch -b hm-bak --impure --flake '${flakeBaseDir}'";
        hm-diff = "home-manager generations | head -n 2 | cut -d' ' -f 7 | tac | xargs ${lib.getExe pkgs.nix} store diff-closures";
      };
    };
  };
}
