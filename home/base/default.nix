{ config, ... }:

{
  home = {
    homeDirectory = "/home/${config.home.username}";

    sessionPath = [
      "$HOME/bin"
    ];

    enableNixpkgsReleaseCheck = true;
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
