{
  custom = {
    base.non-nixos = {
      enable = true;
      home-manager.autoUpgrade.enable = true;
    };

    users = {
      demo.enable = true;
    };

    roles = {
      desktop.enable = true;
      web.enable = true;
    };
  };

  home.stateVersion = import ./state-version.nix;
}
