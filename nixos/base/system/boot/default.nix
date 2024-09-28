{
  boot = {
    # Use the systemd-boot EFI boot loader.
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        memtest86.enable = true;
      };
    };
  };
}
