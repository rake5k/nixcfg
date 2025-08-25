{
  config,
  lib,
  pkgs,
  ...
}:

let

  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isLinux;

in

mkIf (isLinux && !config.custom.roles.mobile.enable) {
  home.packages = with pkgs; [
    parted
    exfat
    samba
  ];
}
