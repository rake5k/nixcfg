{
  custom = {
    base.non-nixos.enable = true;
    users.christian.enable = true;
  };

  home.stateVersion = import ./state-version.nix;
}
