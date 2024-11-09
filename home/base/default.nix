{
  config,
  lib,
  pkgs,
  ...
}:

{
  home = {
    homeDirectory = lib.mkDefault "/home/${config.home.username}";

    sessionPath = [ "$HOME/bin" ];

    enableNixpkgsReleaseCheck = true;
  };

  news.display = "silent";

  xdg.userDirs = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    createDirectories = true;
  };
}
