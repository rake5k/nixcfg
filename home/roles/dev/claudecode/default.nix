{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.roles.dev.claudecode;

  claude-seccomp = pkgs.callPackage ../../../../pkgs/claude-seccomp { };

  # Merge two settings attrsets like `recursiveUpdate`, but concatenate the
  # `permissions.{allow,deny,ask}` lists instead of letting the right-hand side
  # replace them. This lets downstream flakes append permissions without having
  # to redeclare the full list.
  mergeSettings =
    a: b:
    let
      base = lib.recursiveUpdate a b;
      mergePerm = key: (a.permissions.${key} or [ ]) ++ (b.permissions.${key} or [ ]);
      hasPermissions = (a ? permissions) || (b ? permissions);
    in
    base
    // lib.optionalAttrs hasPermissions {
      permissions =
        (a.permissions or { })
        // (b.permissions or { })
        // {
          allow = mergePerm "allow";
          deny = mergePerm "deny";
          ask = mergePerm "ask";
        };
    };
in
{
  options.custom.roles.dev.claudecode = {
    enable = lib.mkEnableOption "claude-code";
    host = lib.mkOption {
      type = lib.types.enum [
        "local"
        "hyperion"
        "cloud"
      ];
      default = "cloud";
      description = "Backend host configuration to use";
    };
    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Additional settings merged into ~/.claude/settings.json on top of the
        common and host-specific defaults. The `permissions.{allow,deny,ask}`
        lists are concatenated; all other keys follow `lib.recursiveUpdate`
        semantics (right-hand side wins).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      # Only include seccomp on Linux - macOS uses native sandbox
      packages =
        with pkgs;
        [
          unstable.claude-code
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          claude-seccomp # sandbox dependency
        ];

      file =
        # Read all JSON configs and merge based on selected host
        let
          commonSettings = lib.importJSON ./settings_common.json;
          localSettings = lib.importJSON ./settings_local.json;
          hyperionSettings = lib.importJSON ./settings_hyperion.json;
          hostSettings =
            if cfg.host == "hyperion" then
              hyperionSettings
            else if cfg.host == "local" then
              localSettings
            else
              { };
          unifiedSettings = mergeSettings (mergeSettings commonSettings hostSettings) cfg.extraSettings;
        in
        {
          ".claude/CLAUDE.md".source = ./CLAUDE.md;
          ".claude/settings.json".text = builtins.toJSON unifiedSettings;

          # Skills directories
          ".claude/skills/commit".source = ./skills/commit;
          ".claude/skills/ollama".source = ./skills/ollama;
        }
        // lib.optionalAttrs pkgs.stdenv.isLinux {
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
