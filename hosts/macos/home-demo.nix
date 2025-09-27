{ inputs, lib, ... }:

{
  imports = [ "${inputs.self}/users/demo" ];

  custom = {
    base.non-nixos.enable = true;

    roles = {
      containers.enable = true;
      desktop.enable = true;
      dev.enable = true;
      graphics.enable = true;
      homeage.enable = true;
      office.enable = true;
      ops.enable = true;
      web.enable = true;
    };
  };

  home = {
    homeDirectory = lib.mkForce "/Users/demo";
    stateVersion = import ./state-version.nix;
  };
}
