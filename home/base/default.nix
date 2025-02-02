{
  config,
  lib,
  ...
}:

{
  home = {
    homeDirectory = lib.mkDefault "/home/${config.home.username}";

    sessionPath = [ "$HOME/bin" ];

    enableNixpkgsReleaseCheck = true;
  };

  news.display = "silent";
}
