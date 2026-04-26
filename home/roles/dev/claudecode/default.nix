{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.roles.dev.claudecode;

  claude-seccomp = pkgs.callPackage ../../../../pkgs/claude-seccomp { };
in
{
  options.custom.roles.dev.claudecode = {
    enable = lib.mkEnableOption "claude-code";
    host = lib.mkOption {
      type = lib.types.enum [
        "local"
        "hyperion"
      ];
      default = "local";
      description = "Backend host configuration to use";
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        unstable.claude-code
        claude-seccomp # sandbox dependency
      ];

      file =
        # Read all JSON configs and merge based on selected host
        let
          commonSettings = lib.importJSON ./settings_common.json;
          localSettings = lib.importJSON ./settings_local.json;
          hyperionSettings = lib.importJSON ./settings_hyperion.json;
          hostSettings = if cfg.host == "hyperion" then hyperionSettings else localSettings;
          unifiedSettings = lib.recursiveUpdate commonSettings hostSettings;
        in
        {
          ".claude/CLAUDE.md".source = ./CLAUDE.md;
          ".claude/settings.json".text = builtins.toJSON unifiedSettings;

          # Skills directories
          ".claude/skills/commit".source = ./skills/commit;
          ".claude/skills/ollama".source = ./skills/ollama;

          # Seccomp sandbox filter for Claude Code native sandbox
          ".claude/seccomp/apply-seccomp".source = "${claude-seccomp}/share/claude-seccomp/apply-seccomp";
          ".claude/seccomp/unix-block.bpf".source = "${claude-seccomp}/share/claude-seccomp/unix-block.bpf";
          # npm global fallback path (Claude Code UI check looks here before loading settings)
          ".npm/lib/node_modules/@anthropic-ai/sandbox-runtime/vendor/seccomp/x64/apply-seccomp".source =
            "${claude-seccomp}/share/claude-seccomp/apply-seccomp";
          ".npm/lib/node_modules/@anthropic-ai/sandbox-runtime/vendor/seccomp/x64/unix-block.bpf".source =
            "${claude-seccomp}/share/claude-seccomp/unix-block.bpf";
        };
    };
  };
}
