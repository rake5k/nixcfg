{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:

let

  cfg = config.custom.base.non-nixos;

  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    optionalString
    ;

  inherit (pkgs.stdenv) isDarwin isLinux;

in

{

  options = {
    custom.base.non-nixos = {
      enable = mkEnableOption "Config for non NixOS systems";
    };
  };

  config = mkIf cfg.enable {

    custom.base.non-nixos.home-manager.enable = true;

    home = {
      activation.report-changes = config.lib.dag.entryAnywhere ''
        if [[ -n "''${oldGenPath:-}" ]]; then
          ${getExe pkgs.nix} store diff-closures $oldGenPath $newGenPath
        fi
      '';
    };

    nixGL = mkIf (isLinux && !config.custom.roles.mobile.enable) {
      inherit (inputs.nixgl) packages;
      defaultWrapper = "mesa";
      installScripts = [ "mesa" ];
    };

    programs.zsh.envExtra = lib.mkAfter ''
      hash -f

      ${optionalString isDarwin ''
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
