{ inputs }:

let

  inherit (inputs.nixpkgs) lib;

  forEachSystem = with inputs.flake-utils.lib.system; lib.genAttrs [
    aarch64-darwin
    aarch64-linux
    x86_64-darwin
    x86_64-linux
  ];

  pkgsFor = forEachSystem (system: import ./nixpkgs.nix { inherit inputs system; });
  customLibFor = forEachSystem (system:
    let
      pkgs = pkgsFor."${system}";
    in
    inputs.flake-commons.lib
      {
        inherit lib pkgs;
        rootPath = inputs.self;
      } // {
      # Wraps all binary files of the given `pkg` with `nixGL`
      nixGLWrap = pkg: pkgs.runCommand "${pkg.name}-nixgl-wrapped" { } ''
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

      # Wraps the main program of the given `pkg` with `nixGL` and names the wrapper script as given `bin`
      nixGLWrap' = pkg: bin: pkgs.runCommand "${pkg.name}-nixgl-wrapped" { } ''
        mkdir $out
        ln -s ${pkg}/* $out
        rm $out/bin
        mkdir $out/bin
        wrapped_bin=$out/bin/${bin}
        echo "#!${pkgs.bash}/bin/bash" >> $wrapped_bin
        echo "exec ${pkgs.lib.getExe pkgs.nixgl.auto.nixGLDefault} ${pkgs.lib.getExe pkg} \"\$@\"" >> $wrapped_bin
        chmod +x $wrapped_bin
      '';
    });

  homeModulesFor = forEachSystem (system:
    let
      customLib = customLibFor.${system};
    in
    [
      inputs.homeage.homeManagerModules.homeage
      inputs.nix-index-database.hmModules.nix-index

      {
        lib.custom = customLib;
      }
    ]
    ++ customLib.getRecursiveDefaultNixFileList ../home
    ++ customLib.getRecursiveDefaultNixFileList "${inputs.self}/home"
  );

  nameValuePairWrapper = name: fn: system: lib.nameValuePair name (fn system);

  wrapper = builder: name: args: system:
    lib.nameValuePair
      name
      (import builder {
        inherit inputs system name args;
        pkgs = pkgsFor."${system}";
        customLib = customLibFor."${system}";
        homeModules = homeModulesFor."${system}";
      });

  simpleWrapper = builder: system: name: wrapper builder name { } system;

  buildersForSystem = system: builders: lib.listToAttrs (map (b: b system) builders);

in

{
  inherit forEachSystem;
  mkForEachSystem = bs: forEachSystem (system: (buildersForSystem system bs));
  mkForSystem = system: bs: { "${system}" = buildersForSystem system bs; };
  mkApp = wrapper ./builders/mkApp.nix;
  mkBuild = name: args: nameValuePairWrapper name (system: args);
  mkCheck = wrapper ./builders/mkCheck.nix;
  mkDevShell = wrapper ./builders/mkDevShell.nix;
  mkGeneric = nameValuePairWrapper;
  mkHome = simpleWrapper ./builders/mkHome.nix;
  mkNixos = simpleWrapper ./builders/mkNixos.nix;
  mkNixDarwin = simpleWrapper ./builders/mkNixDarwin.nix;
  mkNixOnDroid = simpleWrapper ./builders/mkNixOnDroid.nix;
}
