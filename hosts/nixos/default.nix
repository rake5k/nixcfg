{
  imports = [ ./hardware ];

  custom = {
    base = {
      system.boot.secureBoot = true;
      users = [
        "demo"
        "christian"
      ];
    };
    roles = {
      android.enable = true;
      containers.enable = true;
      desktop.enable = true;
      gaming.enable = true;
      impermanence.enable = true;
      printing.enable = true;
    };
  };

  system.stateVersion = import ./state-version.nix;
}
