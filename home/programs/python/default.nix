{ config, lib, pkgs, machNix, ... }:

with lib;

let

  cfg = config.custom.programs.python;

in

{
  options = {
    custom.programs.python = {
      enable = mkEnableOption "Python";

      requirements = mkOption {
        type = types.lines;
        description = "Python apps and libs to put into path";
        default = "";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      let
        pythonEnv = machNix.mkPython {
          inherit (cfg) requirements;
          ignoreDataOutdated = true;
          python = "python310";
        };
      in
      [ pythonEnv ];
  };
}
