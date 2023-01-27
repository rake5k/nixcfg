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
    nurpkgs = inputs.nixpkgs.legacyPackages."${system}";
    pkgs = import inputs.nixpkgs {
      inherit config system;
    };
  };

  custom = import inputs.nixpkgs {
    inherit system;
    overlays = [
      inputs.i3lock-pixeled.overlay
      inputs.spacevim.overlays.default
    ];
  };

  overlays = [
    (final: prev: {
      inherit (inputs.agenix-cli.packages."${system}") agenix-cli;
      inherit (inputs.kmonad.packages."${system}") kmonad;

      nixgl = inputs.nixgl.packages."${system}".default;

      inherit unstable nur custom;
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
        echo "#!${pkgs.bash}/bin/bash" >> $wrapped_bin
        echo "exec ${pkgs.lib.getExe pkgs.nixgl} $bin \"\$@\"" >> $wrapped_bin
        chmod +x $wrapped_bin
      done
    '';
  };

in

{
  inherit pkgs customLib;
}
