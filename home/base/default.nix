{ config, ... }:

{
  home = {
    homeDirectory = "/home/${config.home.username}";

    sessionPath = [
      "$HOME/bin"
    ];

    enableNixpkgsReleaseCheck = true;

    stateVersion = "22.11";
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
