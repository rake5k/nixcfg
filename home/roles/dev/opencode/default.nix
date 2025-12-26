{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.dev.opencode;

  inherit (lib) mkEnableOption mkIf;

in

{
  options = {
    custom.roles.dev.opencode = {
      enable = mkEnableOption "opencode";
    };
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      package = pkgs.unstable.opencode;
      settings = {
        provider = {
          hyperion = {
            npm = "@ai-sdk/openai-compatible";
            name = "Ollama (hyperion)";
            options.baseURL = "https://ollama.local.harke.ch/v1";
            models = {
              "deepseek-r1:7b".name = "Deepseek r1 7b";
              "deepseek-r1:8b".name = "Deepseek r1 8b";
              "gpt-oss:20b".name = "GPT OSS 20b";
            };
          };
        };
      };
    };
  };
}
