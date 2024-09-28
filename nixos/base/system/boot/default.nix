{ lib, ... }:

{
  boot = {
    # Use the systemd-boot EFI boot loader.
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        consoleMode = lib.mkDefault "max";
        memtest86.enable = true;
      };
    };
  };
}
