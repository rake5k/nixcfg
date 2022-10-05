{ pkgs, ... }:

{
  home.packages = with pkgs; [
    parted
    exfat
    samba
  ];
}
