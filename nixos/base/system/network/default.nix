{
  networking = {
    firewall = {
      enable = true;
      allowPing = true;
    };
    networkmanager.enable = true;
  };

  programs.nm-applet.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}
