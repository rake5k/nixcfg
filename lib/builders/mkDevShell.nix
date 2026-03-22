{ customLib, args, ... }:

customLib.mkShell {
  inherit (args.flake) name;
}
