{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  home.packages = with pkgs; [
    parted
    exfat
    samba
  ];
}
