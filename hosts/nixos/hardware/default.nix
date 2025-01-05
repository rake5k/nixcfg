{ config, lib, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./configuration.nix
    ./disk-config.nix
  ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  virtualisation.virtualbox.guest.enable = true;
}
