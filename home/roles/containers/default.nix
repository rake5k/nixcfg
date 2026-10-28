{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.containers;

in

{
  options = {
    custom.roles.containers = {
      enable = mkEnableOption "Container tooling";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        dive
        kubectl
        skopeo
      ];
      shellAliases = {
        ld = "lazydocker";
      };
    };

    programs = {
      k9s.enable = true;
      lazydocker.enable = true;
      zsh.initContent = ''
        # kubectl autocompletion
        source <(kubectl completion zsh)
      '';
    };
  };
}
