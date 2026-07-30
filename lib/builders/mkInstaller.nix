{
  inputs,
  pkgs,
  customLib,
  name,
  args,
  ...
}:

inputs.nixpkgs.lib.nixosSystem {

  specialArgs = {
    inherit inputs;
  };

  modules = [
    ./modules/nix

    # Installer config
    ../../installer

    {
      lib.custom = customLib;

      networking.hostName = name;

      nixpkgs = {
        inherit pkgs;
      };
    }
  ]
  ++ args.modules or [ ];
}
