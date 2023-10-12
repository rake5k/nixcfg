{ inputs }:

let

  forEachSystem =
    let
      inherit (inputs.flake-utils.lib.system) aarch64-linux x86_64-linux;
    in
    inputs.nixpkgs.lib.genAttrs [
      aarch64-linux
      x86_64-linux
    ];

  pkgsFor = forEachSystem (system: import ./nixpkgs.nix { inherit inputs system; });
  customLibFor = forEachSystem (system:
    let
      pkgs = pkgsFor."${system}";
    in
    inputs.flake-commons.lib
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

  nameValuePairWrapper = name: fn: system: inputs.nixpkgs.lib.nameValuePair name (fn system);

  wrapper = builder: name: args: system:
    inputs.nixpkgs.lib.nameValuePair
      name
      (import builder {
        inherit inputs system name args;
        pkgs = pkgsFor."${system}";
        customLib = customLibFor."${system}";
        homeModules = homeModulesFor."${system}";
      });

  simpleWrapper = builder: system: name: wrapper builder name { } system;

in

{
  inherit forEachSystem;
  mkForEachSystem = bs: forEachSystem (system: (inputs.nixpkgs.lib.listToAttrs (map (b: b system) bs)));
  mkApp = wrapper ./builders/mkApp.nix;
  mkBuild = name: args: nameValuePairWrapper name (system: args);
  mkCheck = wrapper ./builders/mkCheck.nix;
  mkDevShell = wrapper ./builders/mkDevShell.nix;
  mkGeneric = nameValuePairWrapper;
  mkHome = simpleWrapper ./builders/mkHome.nix;
  mkNixos = simpleWrapper ./builders/mkNixos.nix;
  mkNixOnDroid = simpleWrapper ./builders/mkNixOnDroid.nix;
}
