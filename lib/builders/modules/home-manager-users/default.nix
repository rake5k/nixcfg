{ lib, config, ... }:

let

  baseCfg = config.custom.base;

  importHmUser = u:
    import (config.lib.custom.mkHostPath baseCfg.hostname "/home-${u}.nix");
  hmUsers = lib.genAttrs baseCfg.users importHmUser;

in

{
  home-manager.users = hmUsers;
}
