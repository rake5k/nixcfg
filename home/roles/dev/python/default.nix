{ config, lib, pkgs, machNix, ... }:

with lib;

let

  cfg = config.custom.roles.dev.python;

  pythonEnv = machNix.mkPython {
    python = "python39";
  };

in

{
  options = {
    custom.roles.dev.python = {
      enable = mkEnableOption "Python";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      pythonEnv
    ];
  };
}
