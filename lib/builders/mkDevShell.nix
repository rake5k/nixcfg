{ customLib, args, ... }:

customLib.mkShell {
  inherit (args) name;
}
