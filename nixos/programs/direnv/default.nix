{ config, lib, ... }:

with lib;

let

  cfg = config.custom.programs.direnv;

in

{
  options = {
    custom.programs.direnv = {
      enable = mkEnableOption "Direnv config";
    };
  };

  config = mkIf cfg.enable {
    # Nix options for derivations to persist garbage collection
    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  };
}
