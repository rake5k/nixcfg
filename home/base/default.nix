{ config, lib, ... }:

let

  inherit (config.custom.base.non-nixos) isDarwin;

in

{
  home = {
    homeDirectory = lib.mkDefault "/home/${config.home.username}";

    sessionPath = [
      "$HOME/bin"
    ];

    enableNixpkgsReleaseCheck = true;
  };

  xdg.userDirs = lib.mkIf (!isDarwin) {
    enable = true;
    createDirectories = true;
  };
}
