{ lib, config, ... }:

let

  baseCfg = config.custom.base;

  hmUsers = lib.genAttrs baseCfg.users (u: {
    imports = [ (config.lib.custom.mkHostPath baseCfg.hostname "/home-${u}.nix") ];
  });

in

{
  home-manager.users = hmUsers;
}
