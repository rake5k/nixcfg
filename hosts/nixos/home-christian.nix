{
  custom = {
    users.christian.enable = true;

    roles = {
      containers.enable = true;
      desktop = {
        enable = true;
        xserver.enable = true;
      };
      dev.enable = true;
      gaming.enable = true;
      graphics.enable = true;
      homeage.enable = true;
      mobile.enable = true;
      multimedia = {
        enable = true;
        converters.enable = true;
      };
      office = {
        enable = true;
        cli.enable = true;
      };
      ops.enable = true;
      web.enable = true;
    };
  };

  home.stateVersion = import ./state-version.nix;
}
