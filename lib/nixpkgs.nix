{ inputs, system }:

let

  config = {
    allowAliases = false;
    allowUnfree = true;
    nvidia.acceptLicense = true;
  };

in

import inputs.nixpkgs {
  inherit config system;

  overlays =
    let
      unstable = import inputs.nixpkgs-unstable { inherit config system; };
    in
    [
      (_final: _prev: {
        inherit system unstable;

        inherit (inputs.agenix-cli.packages."${system}") agenix-cli;
      })

      inputs.nur.overlays.default
    ];
}
