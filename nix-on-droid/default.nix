{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:

let

  cfg = config.custom.base;

  inherit (lib) hiPrio mkOption types;

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
    environment = {
      etcBackupExtension = ".nod-bak";
      motd = ''

          ___  (_)_ _________  ___  _______/ /______  (_)__/ /
         / _ \/ /\ \ /___/ _ \/ _ \/___/ _  / __/ _ \/ / _  /
        /_//_/_//_\_\    \___/_//_/    \_,_/_/  \___/_/\_,_/

      '';

      packages = with pkgs; [
        diffutils
        findutils
        (hiPrio git)
        gnugrep
        hostname
        man
        openssh
        unixtools.nettools
        unixtools.ping
        unixtools.procps
        unixtools.whereis
        vim
      ];
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

    user.shell = "${pkgs.zsh}/bin/zsh";
  };
}
