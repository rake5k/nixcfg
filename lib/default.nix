{ inputs }:

let

  inherit (inputs.nixpkgs) lib;
  inherit (inputs.nixpkgs.lib) genAttrs nameValuePair listToAttrs;

  forEachSystem = genAttrs (import inputs.systems);

  pkgsFor = forEachSystem (system: import ./nixpkgs.nix { inherit inputs system; });
  customLibFor = forEachSystem (
    system:
    import ./customLib.nix {
      inherit lib inputs;
      pkgs = pkgsFor."${system}";
    }
  );

  homeModulesFor = forEachSystem (
    system:
    let
      customLib = customLibFor.${system};
    in
    [
      inputs.homeage.homeManagerModules.homeage
      inputs.nix-index-database.homeModules.nix-index
      inputs.stylix.homeModules.stylix

      { lib.custom = customLib; }
    ]
    ++ customLib.getRecursiveDefaultNixFileList ../home
    ++ customLib.getRecursiveDefaultNixFileList "${inputs.self}/home"
  );

  nameValuePairWrapper =
    name: fn: system:
    nameValuePair name (fn system);

  wrapper =
    builder: name: args: system:
    nameValuePair name (
      import builder {
        inherit
          inputs
          system
          name
          args
          ;
        pkgs = pkgsFor."${system}";
        customLib = customLibFor."${system}";
        homeModules = homeModulesFor."${system}";
      }
    );

  simpleWrapper =
    builder: system: name:
    wrapper builder name { } system;

  buildersForSystem = system: builders: listToAttrs (map (b: b system) builders);

in

{
  inherit forEachSystem pkgsFor;
  mkForEachSystem = bs: forEachSystem (system: (buildersForSystem system bs));
  mkForSystem = system: bs: { "${system}" = buildersForSystem system bs; };
  mkApp = wrapper ./builders/mkApp.nix;
  mkBuild = name: args: nameValuePairWrapper name (_system: args);
  mkCheck = wrapper ./builders/mkCheck.nix;
  mkDevShell = wrapper ./builders/mkDevShell.nix;
  mkGeneric = nameValuePairWrapper;
  mkHome = simpleWrapper ./builders/mkHome.nix;
  mkNixos = simpleWrapper ./builders/mkNixos.nix;
  mkNixDarwin = simpleWrapper ./builders/mkNixDarwin.nix;
  mkNixOnDroid = simpleWrapper ./builders/mkNixOnDroid.nix;
}
