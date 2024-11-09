{
  config,
  lib,
  pkgs,
  ...
}:

with builtins;
with lib;

let

  inherit (config.lib.custom) genAttrs';

  cfg = config.custom.roles.dev.embedmongo;

  mongodbPkg = pkgs.mongodb;

  mkSymlink = dir: {
    name = ".embedmongo/extracted/${dir}/extractmongod";
    value = {
      source = "${mongodbPkg}/bin/mongod";
    };
  };

in

{
  options = {
    custom.roles.dev.embedmongo = {
      enable = mkEnableOption "Embedmongo";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ mongodbPkg ];

      file = genAttrs' [
        "Linux-B64--2.0.3"
        "Linux-B64--3.2.0"
        "Linux-B64--3.6.2"
        "Linux-B64--3.6.5"
        "Linux-B64--4.0.2"
        "Linux-B64--unknown---3.6.22"
      ] mkSymlink;
    };
  };
}
