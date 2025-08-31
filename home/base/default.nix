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

  # See: https://github.com/nix-community/stylix/issues/1832
  stylix.overlays.enable = false;
}
