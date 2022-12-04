{ inputs, rootPath, system }:

let

  config = {
    allowAliases = false;
    allowUnfree = true;
  };

  unstable = import inputs.nixpkgs-unstable {
    inherit config system;
  };

  nur = import inputs.nur {
    nurpkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    pkgs = import inputs.nixpkgs {
      inherit config system;
    };
  };

  customOverlays = [
    inputs.i3lock-pixeled.overlay
    (final: prev: {
      neovim = inputs.neovim.packages."${system}".default;
    })
  ];

  overlays = [
    (final: prev: {
      inherit unstable nur;
      inherit (inputs.agenix-cli.packages."${system}") agenix-cli;
      inherit (inputs.kmonad.packages."${system}") kmonad;

      custom = prev.lib.composeManyExtensions customOverlays final prev;
    })
  ];

  pkgs = import inputs.nixpkgs {
    inherit config overlays system;
  };

  customLib = inputs.flake-commons.lib {
    inherit (inputs.nixpkgs) lib;
    inherit pkgs rootPath;
  };

  machNix = inputs.mach-nix.lib."${system}";

in

{
  inherit pkgs customLib machNix;
}
