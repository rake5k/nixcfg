{
  imports = [ ./hardware ];

  custom = {
    base.users = [ "demo" "christian" ];
    roles = {
      android.enable = true;
      containers.enable = true;
      desktop.enable = true;
      gaming.enable = true;
      printing.enable = true;
    };
  };

  system.stateVersion = import ./state-version.nix;
}
