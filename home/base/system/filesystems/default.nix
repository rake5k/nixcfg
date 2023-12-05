{ config, lib, pkgs, ... }:

lib.mkIf (!config.custom.base.non-nixos.isDarwin) {
  home.packages = with pkgs; [
    parted
    exfat
    samba
  ];
}
