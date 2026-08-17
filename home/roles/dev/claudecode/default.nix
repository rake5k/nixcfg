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

  codegraph = pkgs.unstable.codegraph;

  # MCP servers passed via `claude --mcp-config`; settings.json has no
  # mcpServers key. Without --strict-mcp-config this merges with the servers
  # already configured in ~/.claude.json instead of replacing them.
  mcpConfigFile = pkgs.writeText "claude-mcp-servers.json" (
    builtins.toJSON {
      mcpServers.codegraph = {
        type = "stdio";
        command = "${codegraph}/bin/codegraph";
        args = [
          "serve"
          "--mcp"
        ];
      };
    }
  );

  # Merge two settings attrsets like `recursiveUpdate`, but concatenate the
  # `permissions.{allow,deny,ask}` and `hooks.<event>` lists instead of letting
  # the right-hand side replace them. This lets downstream flakes append
  # permissions and hook handlers without having to redeclare the full list.
  mergeSettings =
    a: b:
    let
      base = lib.recursiveUpdate a b;
      mergePerm = key: (a.permissions.${key} or [ ]) ++ (b.permissions.${key} or [ ]);
      hasPermissions = (a ? permissions) || (b ? permissions);
      hookEvents = lib.attrNames ((a.hooks or { }) // (b.hooks or { }));
      hasHooks = (a ? hooks) || (b ? hooks);
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
    }
    // lib.optionalAttrs hasHooks {
      hooks = lib.genAttrs hookEvents (event: (a.hooks.${event} or [ ]) ++ (b.hooks.${event} or [ ]));
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

  # `claude-<backend>` wrapper pinning the backend's settings and MCP servers.
  wrapperFor =
    backend:
    pkgs.writeShellScriptBin "claude-${backend}" ''
      exec ${claude-code}/bin/claude \
        --settings ${settingsFileFor backend} \
        --mcp-config ${mcpConfigFile} \
        "$@"
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
        the common defaults. The `permissions.{allow,deny,ask}` and
        `hooks.<event>` lists are concatenated; all other keys follow
        `lib.recursiveUpdate` semantics (right-hand side wins).
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

    # The wiki folder below is inert without it; hosts that must not run
    # Syncthing set `custom.roles.syncthing.enable = mkForce false`.
    custom.roles.syncthing.enable = lib.mkDefault true;

    home = {
      shellAliases.claude = "claude-${cfg.defaultBackend}";

      # Only include seccomp on Linux - macOS uses native sandbox
      packages = [
        claude-code
        codegraph
      ]
      ++ wrappers
      ++ lib.optionals pkgs.stdenv.isLinux [
        claude-seccomp # sandbox dependency
      ];

      file = {
        # The CodeGraph guidance is shared with opencode's AGENTS.md.
        ".claude/CLAUDE.md".text = lib.concatStringsSep "\n" [
          (builtins.readFile ./CLAUDE.md)
          (builtins.readFile ../codegraph.md)
        ];

        # ccstatusline layout (statusLine command set in settings_common.json).
        # Leading git-root-dir widget shows the project name.
        ".config/ccstatusline/settings.json".source = ./ccstatusline.json;

        # Slash commands
        ".claude/commands/wiki.md".source = ./commands/wiki.md;

        # Hooks (registered in settings_common.json)
        ".claude/hooks/wiki-index.sh" = {
          source = ./hooks/wiki-index.sh;
          executable = true;
        };

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

    # L2 knowledge base read and written by /wiki, synced through hyperion.
    # `.git` stays local (per-device .stignore); `maxConflicts = 1` keeps a
    # single copy of a lost race instead of a growing pile of conflict files.
    services.syncthing.settings.folders.LogseqClaude = {
      enable = true;
      devices = [
        config.services.syncthing.settings.devices.hyperion.name
      ];
      id = "oce6r-2p1ft";
      maxConflicts = 1;
      path = "~/Documents/notes/claude";
    };
  };
}
