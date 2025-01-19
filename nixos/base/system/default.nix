{ pkgs, ... }:

{
  custom.base.system.systemd.failure-notification.enable = true;

  environment.systemPackages = with pkgs; [
    lsof
  ];

  services.fwupd.enable = true;
}
