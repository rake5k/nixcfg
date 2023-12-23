{ config, lib, pkgs, ... }:

lib.mkIf config.lib.custom.sys.isLinux {
  home.packages = with pkgs; [
    parted
    exfat
    samba
  ];
}
