{ config, ... }:

{
  services.udiskie.enable = !config.custom.base.non-nixos.isDarwin;
}
