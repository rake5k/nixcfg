{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.custom.roles.gaming;

in

{
  options = {
    custom.roles.gaming = {
      enable = mkEnableOption "Gaming computer config";
    };
  };

  config = mkIf cfg.enable {
    # open ports for steam stream and some games
    networking.firewall.allowedTCPPorts = [ 27036 27037 ] ++ (range 27015 27030);
    networking.firewall.allowedUDPPorts = [ 4380 27036 ] ++ (range 27000 27031);

    programs.steam.enable = true;

    # Gaming 32bit
    #hardware.opengl.driSupport32Bit = true;
    #hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
    #hardware.pulseaudio.support32Bit = true;

    # Xbox controller
    hardware.xpadneo.enable = true;
    #boot.extraModprobeConfig = '' options bluetooth disable_ertm=1 '';
  };
}
