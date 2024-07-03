{ inputs, system }:

let

  config = {
    allowAliases = false;
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-27.3.11"
    ];
  };

in

import inputs.nixpkgs {
  inherit config system;

  overlays =
    let
      unstable = import inputs.nixpkgs-unstable {
        inherit config system;
      };
    in
    [
      (final: prev: {
        inherit system unstable;

        inherit (inputs.agenix-cli.packages."${system}") agenix-cli;
      })

      inputs.nixgl.overlays.default
      inputs.nur.overlay
    ];
}
