{ inputs, system }:

let

  config = {
    allowAliases = false;
    allowUnfree = true;
  };

in

import inputs.nixpkgs {
  inherit config system;

  overlays =
    let
      unstable = import inputs.nixpkgs-unstable {
        inherit config system;
      };

      custom = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.spacevim.overlays.default
        ];
      };
    in
    [
      (final: prev: {
        inherit system unstable custom;

        inherit (inputs.agenix-cli.packages."${system}") agenix-cli;
      })

      inputs.kmonad.overlays.default
      inputs.nixgl.overlays.default
      inputs.nur.overlay
    ];
}
