{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.programs.herdr;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    optionalAttrs
    types
    ;

  package = pkgs.unstable.herdr;

  toml = pkgs.formats.toml { };

  # herdr's color tokens (catppuccin names) mapped to stylix's base16 palette.
  # The backgrounds stay "reset" so the terminal's own background and opacity
  # show through.
  stylixTheme =
    let
      c = config.lib.stylix.colors.withHashtag;
    in
    {
      panel_bg = "reset";
      sidebar_bg = "reset";
      active_row_bg = c.base01;
      selection_bg = c.base02;
      surface_dim = c.base01;
      surface0 = c.base01;
      surface1 = c.base02;
      overlay0 = c.base03;
      overlay1 = c.base04;
      subtext0 = c.base04;
      text = c.base05;
      accent = c.base0D;
      red = c.base08;
      peach = c.base09;
      yellow = c.base0A;
      green = c.base0B;
      teal = c.base0C;
      blue = c.base0D;
      mauve = c.base0E;
    };

in

{
  options = {
    custom.programs.herdr = {
      enable = mkEnableOption "herdr terminal workspace manager";

      settings = mkOption {
        inherit (toml) type;
        default = { };
        description = ''
          herdr `config.toml` settings. See the Configuration page in
          <https://herdr.dev/llms.txt>.
        '';
      };

      skill = mkOption {
        type = types.path;
        readOnly = true;
        default = "${package}/share/skills/herdr/herdr";
        description = ''
          The `herdr` agent skill shipped with the package, for the coding
          agents to link into their skills directory.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ package ];

    custom.programs.herdr.settings = {
      # herdr writes this on first run; preset since the file is read-only.
      onboarding = false;
      # stylix's palette when enabled, else the outer terminal's.
      theme = {
        name = "terminal";
      }
      // optionalAttrs config.stylix.enable { custom = stylixTheme; };
      # Desktop notifications through the outer terminal (kitty's OSC 99): the
      # `system` mode needs notify-send and a session bus, which a container lacks.
      ui.toast.delivery = "terminal";
      # Updates come through nixpkgs.
      update.version_check = false;
    };

    xdg.configFile."herdr/config.toml".source = toml.generate "herdr-config.toml" cfg.settings;
  };
}
