{
  zramSwap = {
    enable = true;
    priority = 100;
  };

  # Since we have "fast" swap, we can increase swappiness
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
  };
}
