{
  config,
  lib,
  ...
}:

{
  home = {
    homeDirectory = lib.mkDefault "/home/${config.home.username}";

    sessionPath = [
      "$HOME/bin"
      "$HOME/.local/bin"
    ];

    enableNixpkgsReleaseCheck = true;
  };

  news.display = "silent";

  # See: https://github.com/nix-community/stylix/issues/1832
  stylix.overlays.enable = false;

  # Stylix has no release-26.05 branch yet; we track release-25.11 against nixpkgs 26.05.
  stylix.enableReleaseChecks = false;
}
