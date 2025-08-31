# See: https://github.com/nix-community/nix-on-droid/issues/436

{ lib, ... }:

{
  options.lib = lib.mkOption {
    type = with lib.types; attrsOf attrs;
  };

  config = {
    # See: https://github.com/nix-community/stylix/issues/1818
    stylix.overlays.enable = false;
  };
}
