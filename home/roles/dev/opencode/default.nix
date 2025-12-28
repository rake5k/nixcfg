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
              "qwen2.5-coder:3b-8k".name = "Qwen 2.5 Coder 3b 8k";
              "qwen2.5-coder:3b-16k".name = "Qwen 2.5 Coder 3b 16k";
              "qwen2.5-coder:3b-32k".name = "Qwen 2.5 Coder 3b 32k";
              "qwen2.5-coder:7b-8k".name = "Qwen 2.5 Coder 7b 8k";
              "qwen2.5-coder:7b-16k".name = "Qwen 2.5 Coder 7b 16k";
              "qwen2.5-coder:7b-32k".name = "Qwen 2.5 Coder 7b 32k";
            };
          };
        };
      };
    };
  };
}
