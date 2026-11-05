{ config, lib, ... }:

let

  cfg = config.custom.users.christian.shell.starship;
  starshipCfg = config.programs.starship;

  inherit (lib)
    getExe
    mkAfter
    mkEnableOption
    mkIf
    ;

in

{
  options = {
    custom.users.christian.shell.starship = {
      enable = mkEnableOption "Starship";
    };
  };

  config = mkIf cfg.enable {
    # Home Manager's bash integration, with the generated config from the store
    # rather than ~/.config, which shells without Home Manager lack. Last, as
    # the prompt hooks PROMPT_COMMAND.
    custom.users.christian.shell.portableRc = mkAfter ''
      export STARSHIP_CONFIG=${config.home.file.${starshipCfg.configPath}.source}
      if [[ $TERM != "dumb" ]]; then
        eval "$(${getExe starshipCfg.package} init bash --print-full-init)"
      fi
    '';

    programs.starship = {
      enable = true;
      settings = {
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
          vimcmd_symbol = "[V](bold green)";
        };
        nix_shell = {
          symbol = "❄ ";
        };
        package = {
          symbol = " ";
        };
      };
    };
  };
}
