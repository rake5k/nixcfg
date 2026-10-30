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
    types
    ;

  package = pkgs.unstable.herdr;

  toml = pkgs.formats.toml { };

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
      # Follows the outer terminal's (stylix) palette.
      theme.name = "terminal";
      # Updates come through nixpkgs.
      update.version_check = false;
    };

    xdg.configFile."herdr/config.toml".source = toml.generate "herdr-config.toml" cfg.settings;
  };
}
