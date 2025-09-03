{
  lib,
  config,
  pkgs,
  ...
}:

let

  cfg = config.custom.base.non-nixos.home-manager;

  inherit (lib)
    getExe
    mkIf
    mkEnableOption
    mkOption
    types
    ;
in

{
  options = {
    custom.base.non-nixos.home-manager = {
      enable = mkEnableOption "Config for non NixOS systems";

      flake = mkOption {
        type = types.str;
        default = "github:rake5k/nixcfg";
        description = "Flake URI of the Nix-on-Droid configuration to build.";
      };
    };
  };

  config = mkIf cfg.enable {

    home = {
      packages = with pkgs; [ home-manager ];

      shellAliases = {
        hm-switch = "home-manager switch -b hm-bak --impure --flake '${cfg.flake}'";
        hm-diff = "home-manager generations | head -n 2 | cut -d' ' -f 7 | tac | xargs ${getExe pkgs.nix} store diff-closures";
      };
    };
  };
}
