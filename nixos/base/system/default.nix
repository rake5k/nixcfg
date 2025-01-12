{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    lsof
  ];

  services.fwupd.enable = true;
}
