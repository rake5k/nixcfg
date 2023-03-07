{ inputs, pkgs, customLib, name, args, ... }:

let

  file = "${inputs.self}/flake/apps/${args.file}";
  mkPath = args.path or (pkgs: [ ]);

in

inputs.flake-utils.lib.mkApp {
  drv = customLib.mkScript
    name
    file
    (mkPath pkgs)
    (args.envs or { });
}
