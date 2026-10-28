{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.programs.herdr;

  inherit (lib) mkEnableOption mkIf;

  toml = pkgs.formats.toml { };

  # Config reference: https://herdr.dev/llms.txt
  settings = {
    # herdr writes this on first run; preset since the file is read-only.
    onboarding = false;
    # Follows the outer terminal's (stylix) palette.
    theme.name = "terminal";
    # Updates come through nixpkgs.
    update.version_check = false;
  };

in

{
  options = {
    custom.programs.herdr = {
      enable = mkEnableOption "herdr terminal workspace manager";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.unstable.herdr ];

    xdg.configFile."herdr/config.toml".source = toml.generate "herdr-config.toml" settings;
  };
}
