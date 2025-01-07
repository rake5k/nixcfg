{
  lib,
  pkgs,
  inputs,
}:

inputs.flake-commons.lib {
  inherit lib pkgs;
  flake = inputs.self;
}
