{ lib, config, ... }:

let

  cfg = config.custom.base;

in

{
  options = with lib; {
    custom.base = {
      hostname = mkOption {
        type = types.str;
        description = "Host name.";
      };

      users = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = "List of user names.";
      };
    };
  };

  config = {
    # Make sure the nix daemon always runs
    services.nix-daemon.enable = true;
  };
}
