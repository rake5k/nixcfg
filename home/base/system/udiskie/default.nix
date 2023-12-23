{ config, ... }:

{
  services.udiskie.enable = config.lib.custom.sys.isLinux;
}
