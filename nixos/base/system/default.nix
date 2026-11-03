{ pkgs, ... }:

{
  custom.base.system.systemd.failure-notification.enable = true;

  environment.systemPackages = with pkgs; [
    lsof
    p7zip
  ];

  services.fwupd.enable = true;
}
