{ inputs, pkgs, customLib, name, args, ... }:

let

  file = "${inputs.self}/lib/apps/${args.file}";
  mkPath = args.path or (pkgs: [ ]);
  script = customLib.mkScript
    name
    file
    (mkPath pkgs)
    (args.envs or { });

in

{
  type = "app";
  program = "${script}/bin/${name}";
}
