{ config, lib, ... }:

with lib;

let

  username = "demo";
  cfg = config.custom.users."${username}";

in

{
  options = {
    custom.users."${username}" = {
      enable = mkEnableOption "User config";
    };
  };

  config = mkIf cfg.enable {
    home = {
      inherit username;
      homeDirectory = "/home/${username}";
    };
  };
}
