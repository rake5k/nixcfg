{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.roles.dev.claudecode;

  claude-code = pkgs.unstable.claude-code;
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

  commonSettings = lib.importJSON ./settings_common.json;

  # Per-backend env overrides. `cloud` adds nothing (native Anthropic endpoint).
  backendEnv = {
    cloud = { };
    local = (lib.importJSON ./settings_local.json).env;
    hyperion = (lib.importJSON ./settings_hyperion.json).env;
  };

  # Full, self-contained settings for one backend: common + backend env +
  # extraSettings, generated as a store file passed to `claude --settings`.
  settingsFileFor =
    backend:
    let
      backendSettings = mergeSettings commonSettings { env = backendEnv.${backend}; };
      unified = mergeSettings backendSettings cfg.extraSettings;
    in
    pkgs.writeText "claude-settings-${backend}.json" (builtins.toJSON unified);

  # `claude-<backend>` wrapper pinning the backend's settings file.
  wrapperFor =
    backend:
    pkgs.writeShellScriptBin "claude-${backend}" ''
      exec ${claude-code}/bin/claude --settings ${settingsFileFor backend} "$@"
    '';

  wrappers = map wrapperFor cfg.backends;
in
{
  options.custom.roles.dev.claudecode = {
    enable = lib.mkEnableOption "claude-code";
    backends = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "cloud"
          "local"
          "hyperion"
        ]
      );
      default = [
        "cloud"
        "hyperion"
      ];
      description = ''
        Backends to expose as `claude-<backend>` commands. Each generates a
        self-contained settings file passed via `claude --settings`. `cloud`
        uses the native Anthropic endpoint; `local` and `hyperion` point at
        ollama (see settings_local.json / settings_hyperion.json).
      '';
    };
    defaultBackend = lib.mkOption {
      type = lib.types.enum [
        "cloud"
        "local"
        "hyperion"
      ];
      default = "cloud";
      description = ''
        Backend the bare `claude` shell alias resolves to. Must be listed in
        `backends`.
      '';
    };
    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Additional settings merged into every backend's settings file on top of
        the common defaults. The `permissions.{allow,deny,ask}` lists are
        concatenated; all other keys follow `lib.recursiveUpdate` semantics
        (right-hand side wins).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.elem cfg.defaultBackend cfg.backends;
        message = "custom.roles.dev.claudecode.defaultBackend (${cfg.defaultBackend}) must be listed in backends ([ ${lib.concatStringsSep " " cfg.backends} ]).";
      }
    ];

    home = {
      shellAliases.claude = "claude-${cfg.defaultBackend}";

      # Only include seccomp on Linux - macOS uses native sandbox
      packages = [
        claude-code
      ]
      ++ wrappers
      ++ lib.optionals pkgs.stdenv.isLinux [
        claude-seccomp # sandbox dependency
      ];

      file = {
        ".claude/CLAUDE.md".source = ./CLAUDE.md;

        # ccstatusline layout (statusLine command set in settings_common.json).
        # Leading git-root-dir widget shows the project name.
        ".config/ccstatusline/settings.json".source = ./ccstatusline.json;

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
