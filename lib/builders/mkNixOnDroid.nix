{ inputs, system, pkgs, customLib, homeModules, name, ... }:

let

  inherit (pkgs) lib;

in

inputs.nix-on-droid.lib.nixOnDroidConfiguration {
  modules = [
    "${inputs.self}/hosts/${name}"

    {
      _file = ./mkNixOnDroid.nix;

      options = {
        lib = lib.mkOption {
          type = with lib.types; attrsOf attrs;
          default = { };
          description = ''
            This option allows modules to define helper functions,
            constants, etc.
          '';
        };
      };

      config = {
        custom.base.hostname = name;

        lib.custom = customLib;
      };
    }
  ]
  ++ customLib.getRecursiveDefaultNixFileList ../../nix-on-droid;

  extraSpecialArgs = {
    inherit inputs pkgs homeModules;
  };
}
