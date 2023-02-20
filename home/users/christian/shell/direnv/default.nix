{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.users.christian.shell.direnv;
  nonNixosCfg = config.custom.base.non-nixos;

in

{
  options = {
    custom.users.christian.shell.direnv = {
      enable = mkEnableOption "Direnv";
    };
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      stdlib = ''
        direnv reload

        : ''${XDG_CACHE_HOME:=$HOME/.cache}
        declare -A direnv_layout_dirs
        direnv_layout_dir() {
            echo "''${direnv_layout_dirs[$PWD]:=$(
                echo -n "$XDG_CACHE_HOME"/direnv/layouts/
                echo -n "$PWD" | sha1sum | cut -d ' ' -f 1
            )}"
        }
      '';
    };

    home.sessionVariables = {
      DIRENV_LOG_FORMAT = "";
    };

    xdg.configFile."nix/nix.conf" = mkIf nonNixosCfg.enable {
      text = ''
        keep-derivations = true
        keep-outputs = true
      '';
    };
  };
}
