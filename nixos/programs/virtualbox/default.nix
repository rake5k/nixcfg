{ config, lib, ... }:

with lib;

let

  cfg = config.custom.programs.virtualbox;
  baseCfg = config.custom.base;

in

{
  options = {
    custom.programs.virtualbox.enable = mkEnableOption "Virtualbox";
  };

  config = mkIf cfg.enable {
    users.groups.vboxusers.members = baseCfg.users;
    virtualisation.virtualbox.host.enable = true;
  };
}
