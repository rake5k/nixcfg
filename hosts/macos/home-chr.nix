{
  custom = {
    base.non-nixos.enable = true;
    users.christian.enable = true;

    roles = {
      containers.enable = true;
      dev.enable = true;
      graphics.enable = true;
      homeage.enable = true;
      office.enable = true;
      ops.enable = true;
      web.enable = true;
    };
  };

  home.stateVersion = import ./state-version.nix;
}
