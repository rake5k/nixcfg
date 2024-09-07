{ lib, config, pkgs, ... }:

let

  cfg = config.custom.base.non-nixos;

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

    custom.base.non-nixos.home-manager.enable = true;

    home = {
      activation.report-changes = config.lib.dag.entryAnywhere ''
        ${lib.getExe pkgs.nix} store diff-closures $oldGenPath $newGenPath || true
      '';
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
