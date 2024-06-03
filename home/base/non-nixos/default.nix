{ lib, config, pkgs, ... }:

let

  cfg = config.custom.base.non-nixos;
  flakeBaseDir = config.home.homeDirectory + "/.nix-config";

  inherit (pkgs.stdenv) isDarwin isLinux;

in

{

  options = {
    custom.base.non-nixos = {
      enable = lib.mkEnableOption "Config for non NixOS systems";

      installNix = lib.mkEnableOption "Nix installation" // { default = true; };
    };
  };

  config = lib.mkIf cfg.enable {

    home = {
      activation.report-changes = config.lib.dag.entryAnywhere ''
        ${lib.getExe pkgs.nix} store diff-closures $oldGenPath $newGenPath || true
      '';

      packages = with pkgs; [
        unstable.home-manager
      ];

      shellAliases = {
        hm-switch = "home-manager switch -b hm-bak --impure --flake '${flakeBaseDir}'";
        hm-diff = "home-manager generations | head -n 2 | cut -d' ' -f 7 | tac | xargs ${lib.getExe pkgs.nix} store diff-closures";
      };
    };

    nix = {
      package = lib.mkForce pkgs.nix;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
    };

    programs.zsh.envExtra = lib.mkAfter ''
      hash -f

      ${lib.optionalString isDarwin ''
        # Nix
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi
        # End Nix
      ''}
    '';

    targets.genericLinux.enable = isLinux;
  };
}
