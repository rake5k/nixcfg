{
  nix.optimise.automatic = true;

  # See: https://github.com/LnL7/nix-darwin/issues/1082#issuecomment-2358489238
  nixpkgs.flake = {
    setFlakeRegistry = false;
    setNixPath = false;
  };
}
