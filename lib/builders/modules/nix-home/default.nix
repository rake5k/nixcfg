{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let

  nixCommons = import ../nix-commons { inherit lib inputs pkgs; };

  nixAccessTokensSecret = "nix-access-tokens";

in

{
  custom.roles.homeage.secrets = [ nixAccessTokensSecret ];

  nix = {
    inherit (nixCommons.nix) package registry;

    extraOptions = ''
      !include ${config.custom.roles.homeage.secretsPath}/${nixAccessTokensSecret}
    '';

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
