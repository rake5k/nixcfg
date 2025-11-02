{ inputs, system }:

let

  config = {
    allowAliases = false;
    allowUnfree = true;
    nvidia.acceptLicense = true;
    permittedInsecurePackages = [
      "broadcom-sta-6.30.223.271-57-6.12.55"
    ];
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
      inputs.nvidia-patch.overlays.default
    ];
}
