{ config, ... }:

{
  home = {
    homeDirectory = "/home/${config.home.username}";

    sessionPath = [
      "$HOME/bin"
    ];

    enableNixpkgsReleaseCheck = true;

    stateVersion = "22.05";
  };
}
