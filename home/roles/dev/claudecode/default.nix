{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.roles.dev.claudecode;

  claude-code = pkgs.unstable.claude-code;
  claude-agent-acp = pkgs.unstable.claude-agent-acp;
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

  # Merge two settings attrsets like `recursiveUpdate`, but concatenate lists
  # instead of letting the right-hand side replace them. This lets downstream
  # flakes append to `permissions.{allow,deny,ask}`, `hooks.<event>` and the
  # `sandbox` rule lists without having to redeclare the shared entries.
  mergeSettings =
    a: b:
    let
      mergeValue =
        x: y:
        if lib.isList x && lib.isList y then
          x ++ y
        else if lib.isAttrs x && lib.isAttrs y then
          mergeAttrs x y
        else
          y;
      mergeAttrs =
        x: y: x // lib.mapAttrs (name: value: if x ? ${name} then mergeValue x.${name} value else value) y;
    in
    mergeAttrs a b;

  # `additionalDirectories` turns the wiki into a working directory of every
  # session, so `/wiki` reads and writes it without `/add-dir` and without
  # tripping `permissions.blockReadsOutsideWorkingDirectories`. The key takes
  # plain directory paths, hence the interpolated home instead of a `~` entry
  # in settings_common.json.
  commonSettings = mergeSettings (lib.importJSON ./settings_common.json) {
    permissions.additionalDirectories = [ "${config.home.homeDirectory}/Documents/notes/claude" ];
  };

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
      unified = mergeSettings (mergeSettings backendSettings cfg.extraSettings) (
        cfg.extraBackendSettings.${backend} or { }
      );
    in
    pkgs.writeText "claude-settings-${backend}.json" (builtins.toJSON unified);

  # `claude-<backend>` wrapper pinning the backend's settings and MCP servers.
  wrapperFor =
    backend:
    pkgs.writeShellScriptBin "claude-${backend}" ''
      # `home.profileDirectory` puts ~/.nix-profile on PATH, which the Bash
      # sandbox does not materialize, leaving every Home Manager package
      # unreachable. Prepend the profile directory nix itself manages; the
      # path is absent where home-manager installs through the NixOS module.
      export PATH="$HOME/.local/state/nix/profiles/profile/bin:$PATH"

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
        the common defaults. Lists are concatenated; all other keys follow
        `lib.recursiveUpdate` semantics (right-hand side wins).
      '';
    };
    extraBackendSettings = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = ''
        Settings merged on top of `extraSettings` for a single backend, keyed
        by backend name. Holds what is bound to one endpoint rather than to the
        machine — model tags, context window — which set globally would follow
        `claude-cloud` to the Anthropic API and name a model it does not serve.
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
        claude-agent-acp
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
