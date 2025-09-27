{ inputs, ... }:

{
  imports = [ "${inputs.self}/users/demo" ];

  custom.roles.desktop.enable = true;

  home.stateVersion = import ./state-version.nix;
}
