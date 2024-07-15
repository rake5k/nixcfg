{
  nix = {
    gc = {
      automatic = true;
      dates = "04:00";
      options = "--delete-older-than 7d";
    };
    optimise.automatic = true;
  };
}
