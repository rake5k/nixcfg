{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:

let

  cfg = config.custom.base;

  inherit (lib) getExe mkOption types;

in

{
  options = {
    custom.base = {
      hostname = mkOption {
        type = types.str;
        description = "Host name.";
      };
    };
  };

  config = {
    android-integration = {
      am.enable = true;
      termux-open.enable = true;
      termux-open-url.enable = true;
      termux-reload-settings.enable = true;
      termux-setup-storage.enable = true;
    };

    environment = {
      etcBackupExtension = ".nod-bak";
      motd = ''

          ___  (_)_ _________  ___  _______/ /______  (_)__/ /
         / _ \/ /\ \ /___/ _ \/ _ \/___/ _  / __/ _ \/ / _  /
        /_//_/_//_\_\    \___/_//_/    \_,_/_/  \___/_/\_,_/

      '';
    };

    home-manager.config = "${inputs.self}/hosts/${cfg.hostname}/home-nix-on-droid.nix";
    nix.package = pkgs.nix;

    terminal.font =
      let
        fontPackage = pkgs.nerd-fonts.zed-mono;
        fontPath = "/share/fonts/truetype/NerdFonts/ZedMono/ZedMonoNerdFont-Regular.ttf";
      in
      fontPackage + fontPath;

    time.timeZone = "Europe/Zurich";

    user.shell = getExe pkgs.zsh;
  };
}
