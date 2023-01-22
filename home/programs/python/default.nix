{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.programs.python;

in

{
  options = {
    custom.programs.python = {
      enable = mkEnableOption "Python";

      packages = mkOption {
        type = with types; listOf package;
        description = "Python apps and libs to put into path";
        example = with pkgs.python3Packages; [
          (buildPythonPackage rec {
            pname = "vimwiki-cli";
            version = "1.0.2";
            src = fetchPypi {
              inherit pname version;
              sha256 = "sha256-sqiNyUdskFGQrqt0vzYv20U5REoN9LzohK7l6fofowc=";
            };
            propagatedBuildInputs = [ click ];
            doCheck = false;
          })
        ];
        default = [ ];
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      let
        pythonPackages = p: with p; cfg.packages;
        pythonEnv = pkgs.python3.withPackages pythonPackages;
      in
      [ pythonEnv ];
  };
}
