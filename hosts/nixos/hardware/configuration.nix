# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd = {
      availableKernelModules = [
        "ata_piix"
        "ohci_pci"
        "sd_mod"
        "sr_mod"
      ];
      kernelModules = [ "dm-snapshot" ];
      luks.devices.root = {
        device = "/dev/sda2";
        preLVM = true;
      };
    };
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  nix.settings.max-jobs = lib.mkDefault 2;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
