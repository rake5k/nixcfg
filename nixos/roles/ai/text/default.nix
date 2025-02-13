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
      # When using `DynamicUser` in sytemd services, we can't persist the actual state directory.
      # See: https://github.com/nix-community/impermanence/issues/93
      "/var/lib/private/ollama"
      "/var/lib/private/open-webui"
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
