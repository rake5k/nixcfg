{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.ai.text;

  inherit (lib) mkEnableOption mkIf;

  ollamaCfg = config.services.ollama;

in

{
  options = {
    custom.roles.ai.text = {
      enable = mkEnableOption "Text-generating LLM";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      base.system.btrfs.impermanence.extraDirectories = [
        # When using `DynamicUser` in sytemd services, we can't persist the actual state directory.
        # See: https://github.com/nix-community/impermanence/issues/93
        "/var/lib/private/ollama"
        "/var/lib/private/open-webui"
      ];

      roles.backup.rsync.jobs.backup.excludes = [
        "/persist/var/lib/private/ollama/models"
        "/var/lib/private/ollama/models"
      ];
    };

    services = {
      ollama = {
        enable = true;
        package =
          if ollamaCfg.acceleration == null then
            pkgs.unstable.ollama
          else if ollamaCfg.acceleration == "cuda" || ollamaCfg == "rocm" || ollamaCfg == "vulkan" then
            pkgs.unstable."ollama-${ollamaCfg.acceleration}"
          else
            pkgs.unstable.ollama-cpu;
        port = 11434;
      };
      open-webui = {
        enable = true;
        package = pkgs.unstable.open-webui;
        port = 11435;
      };
    };
  };
}
