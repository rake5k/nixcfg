{ lib, ... }:

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
}
