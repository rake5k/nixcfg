{ config, lib, ... }:

with lib;

let

  cfg = config.custom.roles.android;

in

{
  options = {
    custom.roles.android = {
      enable = mkEnableOption "Android tooling";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.waydroid.enable = true;

    # The kernel ships only the nftables backend; waydroid-net.sh defaults to
    # iptables-legacy, which needs the absent ip_tables modules. Build waydroid
    # against nftables so it uses the nft path instead.
    nixpkgs.overlays = [
      (_final: prev: {
        waydroid = prev.waydroid.override { withNftables = true; };
      })
    ];
  };
}
