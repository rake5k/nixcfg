{ pkgs, ... }:

{
  services.udiskie.enable = pkgs.stdenv.isLinux;
}
