{
  imports = [ ./hardware ];

  custom = {
    base = {
      system.network.wol.interface = "enp4s0";
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
      nas.enable = true;
      printing.enable = true;
    };
  };

  system.stateVersion = import ./state-version.nix;
}
