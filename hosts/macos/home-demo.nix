{ lib, ... }:

{
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

    users.demo.enable = true;
  };

  home = {
    homeDirectory = lib.mkForce "/Users/demo";
    stateVersion = import ./state-version.nix;
  };
}
