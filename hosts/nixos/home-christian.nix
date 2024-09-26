{
  custom = {
    users.christian.enable = true;

    roles = {
      desktop = {
        enable = true;
      };
      homeage.enable = true;
      mobile.enable = true;
      web.enable = true;
    };
  };

  home.stateVersion = import ./state-version.nix;
}
