{ pkgs, ... }:

{
  sound.enable = true;
  hardware = {
    bluetooth.enable = true;
    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
    };
  };
  environment.systemPackages = [ pkgs.pavucontrol ];
}
