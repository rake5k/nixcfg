{ pkgs, ... }:

with pkgs;

{
  fonts.fontconfig.enable = true;

  home.packages = [
    corefonts
  ];
}
