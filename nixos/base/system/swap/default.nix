{ config, lib, pkgs, ... }:

let

  cfg = config.services.az-zram-swap;

in

{
  config = {
    zramSwap = {
      enable = true;
      priority = 100;
    };

    # Since we have "fast" swap, we can increase swappiness
    boot.kernel.sysctl = {
      "vm.swappiness" = 180;
    };
  };
}
