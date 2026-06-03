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

  # Adopt the 26.05 default for the GTK 4 theme (previously `config.gtk.theme`).
  # stylix enables `gtk` for every profile, so set it here rather than in the
  # GTK role; `mkDefault` keeps per-profile overrides working.
  gtk.gtk4.theme = lib.mkDefault null;

  # See: https://github.com/nix-community/stylix/issues/1832
  stylix.overlays.enable = false;
}
