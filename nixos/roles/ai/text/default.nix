{ config, lib, ... }:

let

  cfg = config.custom.roles.ai.text;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.roles.ai.text = {
      enable = mkEnableOption "Text-generating LLM";
    };
  };

  config = mkIf cfg.enable {
    custom.base.system.btrfs.impermanence.extraDirectories = [
      config.services.ollama.home
      config.services.open-webui.stateDir
    ];

    services = {
      ollama = {
        enable = true;
        openFirewall = true;
        port = 11434;
      };
      open-webui = {
        enable = true;
        openFirewall = true;
        port = 11435;
      };
    };
  };
}
