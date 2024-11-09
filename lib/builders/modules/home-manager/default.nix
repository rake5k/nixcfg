{ homeModules, inputs, ... }:

{
  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
    };
    sharedModules = homeModules;
  };
}
