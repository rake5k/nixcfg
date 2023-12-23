{ config, lib, ... }:

{
  home = {
    homeDirectory = lib.mkDefault "/home/${config.home.username}";

    sessionPath = [
      "$HOME/bin"
    ];

    enableNixpkgsReleaseCheck = true;
  };

  xdg.userDirs = lib.mkIf config.lib.custom.sys.isLinux {
    enable = true;
    createDirectories = true;
  };
}
