{ config, lib, ... }:

let

  cfg = config.custom.users.christian.shell.lazygit;
  lazygitCfg = config.programs.lazygit;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.users.christian.shell.lazygit = {
      enable = mkEnableOption "Lazygit";
    };
  };

  config = mkIf cfg.enable {
    # Home Manager's wrapper (`shellWrapperName`, cd to lazygit's last repo on
    # exit) for shells without Home Manager.
    custom.users.christian.shell.portableRc = import ../portable-wrapper.nix {
      name = lazygitCfg.shellWrapperName;
      inherit (lazygitCfg) package;
      run = ''LAZYGIT_NEW_DIR_FILE="$tmp" command lazygit "$@"'';
    };

    programs.lazygit = {
      enable = true;
      settings = {
        gui = {
          useHunkModeInStagingView = false;
        };
      };
    };
  };
}
