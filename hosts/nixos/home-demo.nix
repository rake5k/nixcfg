{
  custom = {
    roles.desktop.enable = true;
    users.demo.enable = true;
  };

  home.stateVersion = import ./state-version.nix;
}
