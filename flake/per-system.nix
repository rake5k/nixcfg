{ inputs, rootPath, system }:

let

  config = {
    allowAliases = false;
    allowUnfree = true;
  };

  unstable = import inputs.nixpkgs-unstable {
    inherit config system;
  };

  nixgl = import inputs.nixpkgs-unstable {
    inherit system;
    overlays = [ inputs.nixgl.overlays.default ];
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

  customLib = inputs.flake-commons.lib
    {
      inherit (inputs.nixpkgs) lib;
      inherit pkgs rootPath;
    } // {
    nixGLWrap = pkg: pkgs.runCommand "${pkg.name}-nixgl-wrapper" { } ''
      mkdir $out
      ln -s ${pkg}/* $out
      rm $out/bin
      mkdir $out/bin
      for bin in ${pkg}/bin/*; do
        wrapped_bin=$out/bin/$(basename $bin)
        echo "exec ${pkgs.lib.getExe nixgl.nixgl.auto.nixGLDefault} $bin \"\$@\"" > $wrapped_bin
        chmod +x $wrapped_bin
      done
    '';
  };

  machNix = inputs.mach-nix.lib."${system}";

in

{
  inherit pkgs customLib machNix;
}
