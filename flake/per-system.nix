{ inputs, system }:

let

  config = {
    allowAliases = false;
    allowUnfree = true;
  };

  unstable = import inputs.nixpkgs-unstable {
    inherit config system;
  };

  custom = import inputs.nixpkgs {
    inherit system;
    overlays = [
      inputs.spacevim.overlays.default
    ];
  };

  overlays = [
    (final: prev: {
      inherit system unstable custom;

      inherit (inputs.agenix-cli.packages."${system}") agenix-cli;
    })

    inputs.kmonad.overlays.default
    inputs.nixgl.overlays.default
    inputs.nur.overlay
  ];

  pkgs = import inputs.nixpkgs {
    inherit config overlays system;
  };

  customLib = inputs.flake-commons.lib
    {
      inherit (inputs.nixpkgs) lib;
      inherit pkgs;
      rootPath = inputs.self;
    } // {
    nixGLWrap = pkg: pkgs.runCommand "${pkg.name}-nixgl-wrapper" { } ''
      mkdir $out
      ln -s ${pkg}/* $out
      rm $out/bin
      mkdir $out/bin
      for bin in ${pkg}/bin/*; do
        wrapped_bin=$out/bin/$(basename $bin)
        echo "#!${pkgs.bash}/bin/bash" >> $wrapped_bin
        echo "exec ${pkgs.lib.getExe pkgs.nixgl.auto.nixGLDefault} $bin \"\$@\"" >> $wrapped_bin
        chmod +x $wrapped_bin
      done
    '';
  };

in

{
  inherit pkgs customLib;
}
