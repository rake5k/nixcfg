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
      neovim = inputs.neovim.packages.default."${system}";
    })
  ];

  overlays = [
    (final: prev: {
      inherit unstable nur;
      inherit (inputs.agenix-cli.packages."${system}") agenix-cli;

      custom = prev.lib.composeManyExtensions customOverlays final prev;
    })
  ];

  pkgs = import inputs.nixpkgs {
    inherit config overlays system;
  };

  customLib = inputs.flake-commons.lib."${system}" {
    inherit (inputs.nixpkgs) lib;
    inherit pkgs rootPath;
  };

  machNix = import inputs.mach-nix {
    inherit pkgs;
  };

in

{
  inherit pkgs customLib machNix;
}
