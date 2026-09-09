{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.dev.zed;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.roles.dev.zed = {
      enable = mkEnableOption "Zed editor";
    };
  };

  config = mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;

      # Only Zed needs these, so keep them off home.packages.
      extraPackages = with pkgs; [
        nil
        nixfmt
      ];

      # Fonts and theme are owned by the stylix zed target.
      userSettings = {
        base_keymap = "JetBrains";
        format_on_save = "on";
        relative_line_numbers = "enabled";
        vim_mode = true;

        agent_servers."claude-acp" = {
          type = "registry";
          default_config_options.model = "default";
          favorite_config_option_values = {
            model = [
              "opus[1m]"
              "claude-fable-5[1m]"
            ];
            mode = [ "auto" ];
          };
        };

        telemetry = {
          diagnostics = false;
          metrics = false;
        };

        languages.Nix.language_servers = [ "nil" ];
        lsp.nil.initialization_options.formatting.command = [ "nixfmt" ];
      };
    };
  };
}
