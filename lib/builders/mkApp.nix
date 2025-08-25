{
  inputs,
  pkgs,
  customLib,
  name,
  args,
  ...
}:

let

  file = "${inputs.self}/lib/apps/${args.file}";
  mkPath = args.path or (_: [ ]);
  script = customLib.mkScript name file (mkPath pkgs) (args.envs or { });

in

{
  inherit (args) meta;
  type = "app";
  program = "${script}/bin/${name}";
}
