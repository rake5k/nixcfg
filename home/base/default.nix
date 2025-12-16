{ config, lib, ... }:

let

  sessionVariables = {
    LANG = "${config.home.language.base}";
  };

in

{
  home = {
    inherit sessionVariables;

    enableNixpkgsReleaseCheck = true;
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    sessionPath = [ "$HOME/bin" ];
  };

  news.display = "silent";

  pam = {
    inherit sessionVariables;
  };

  # See: https://github.com/nix-community/stylix/issues/1832
  stylix.overlays.enable = false;

  systemd.user = {
    inherit sessionVariables;
  };
}
