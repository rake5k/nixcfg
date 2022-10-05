{ inputs, rootPath }:

let

  homeModulesBuilder = { rootPath, customLib, ... }:
    [
      inputs.homeage.homeManagerModules.homeage

      {
        lib.custom = customLib;
      }
    ]
    ++ customLib.getRecursiveDefaultNixFileList ../home
    ++ customLib.getRecursiveDefaultNixFileList (rootPath + "/home");

  nameValuePairSystemWrapper = system: name: fn:
    inputs.nixpkgs.lib.nameValuePair name (fn system);

  wrapper = builder: system: name: args:
    let
      flakeArgs = { inherit inputs rootPath system; };
      perSystem = import ./per-system.nix flakeArgs;

      homeModules = homeModulesBuilder (flakeArgs // perSystem);

      builderArgs = flakeArgs // perSystem // { inherit args homeModules name; };
    in
    import builder builderArgs;

  nameValuePairWrapper = builder: system: name: args:
    inputs.nixpkgs.lib.nameValuePair name (wrapper builder system name args);

  simpleNameValuePairWrapper = builder: system: name:
    nameValuePairWrapper builder system name { };

in

{
  mkHome = simpleNameValuePairWrapper ./builders/mkHome.nix;
  mkNixos = simpleNameValuePairWrapper ./builders/mkNixos.nix;

  eachSystem = builderPerSystem:
    inputs.flake-utils.lib.eachSystem
      [ "aarch64-linux" "x86_64-linux" ]
      (system:
        builderPerSystem {
          mkGeneric = nameValuePairSystemWrapper system;
          mkApp = nameValuePairWrapper ./builders/mkApp.nix system;
          mkCheck = nameValuePairWrapper ./builders/mkCheck.nix system;
          getDevShell = name: inputs.self.devShells."${system}"."${name}";
          mkDevShell = nameValuePairWrapper ./builders/mkDevShell.nix system;
        }
      );
}
