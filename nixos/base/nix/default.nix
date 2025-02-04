{ config, ... }:

let

  nixAccessTokensSecret = "nix-access-tokens";

in

{
  custom.base.agenix.secrets = [ nixAccessTokensSecret ];

  nix = {
    extraOptions = ''
      !include ${config.age.secrets.${nixAccessTokensSecret}.path}
    '';

    gc = {
      automatic = true;
      dates = "04:00";
      options = "--delete-older-than 7d";
    };

    optimise.automatic = true;
  };
}
