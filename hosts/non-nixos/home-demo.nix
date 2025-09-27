{ inputs, ... }:

{
  imports = [ "${inputs.self}/users/demo" ];

  custom = {
    base.non-nixos = {
      enable = true;
      home-manager.autoUpgrade.enable = true;
    };

    roles = {
      desktop.enable = true;
      web.enable = true;
    };
  };

  home.stateVersion = import ./state-version.nix;
}
