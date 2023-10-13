{ inputs, system, pkgs, customLib, homeModules, name, ... }:

let

  inherit (pkgs) lib;
  rootPath = inputs.self;

in

inputs.nix-on-droid.lib.nixOnDroidConfiguration {
  modules = [
    {
      _file = ./mkNixOnDroid.nix;

      options.lib = lib.mkOption {
        type = lib.types.attrsOf lib.types.attrs;
        default = { };
        description = ''
          This option allows modules to define helper functions,
          constants, etc.
        '';
      };

      config.lib.custom = customLib;
    }
  ]
  ++ customLib.getRecursiveDefaultNixFileList ../../nix-on-droid;

  extraSpecialArgs = {
    inherit inputs pkgs homeModules;
  };
}
