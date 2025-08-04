# See: https://github.com/nix-community/nix-on-droid/issues/436

{ lib, ... }:

{
  options.lib = lib.mkOption {
    type = with lib.types; attrsOf attrs;
  };
}
