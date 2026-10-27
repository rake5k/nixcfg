{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.roles.dev.claudecode;

  inherit (config.lib.custom) genAttrs';
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  claude-code = pkgs.unstable.claude-code;
  claude-agent-acp = pkgs.unstable.claude-agent-acp;
  claude-seccomp = pkgs.callPackage ../../../../pkgs/claude-seccomp { };
  ccstatusline = pkgs.callPackage ../../../../pkgs/ccstatusline { };

  codegraph = pkgs.unstable.codegraph;

  # /wiki is llm-wiki's root skill, copied like its setup.sh does: the plugin
  # placeholders become the wiki root and the source tree (`/wiki setup` runs
  # its scripts/init-wiki.sh), `/llm-wiki` becomes `/wiki`. wiki.patch carries
  # the local changes (Syncthing conflict copies, env-expanded memory paths).
  wikiRoot = "${config.home.homeDirectory}/Documents/notes/claude";
  llm-wiki = pkgs.applyPatches {
    name = "llm-wiki";
    src = pkgs.fetchFromGitHub {
      owner = "rake5k";
      repo = "llm-wiki";
      rev = "7348a4aea7ebe07045dacd619f09802e264b21a8";
      hash = "sha256-V0ofzh/kthFW+9sxP4E/meOd+pgA2OsrtS1DiiT88o0=";
    };
    patches = [ ./commands/wiki.patch ];
  };
  wikiCommand =
    pkgs.runCommand "wiki.md"
      {
        wikiRootVar = "\${user_config.wiki_path}";
        pluginRootVar = "\${CLAUDE_PLUGIN_ROOT}";
      }
      ''
        substitute ${llm-wiki}/SKILL.md $out \
          --replace-fail "$wikiRootVar" ${lib.escapeShellArg wikiRoot} \
          --replace-fail "$pluginRootVar" ${llm-wiki} \
          --replace-fail 'name: llm-wiki' 'name: wiki' \
          --replace-fail /llm-wiki /wiki
      '';

  # Skills cherry-picked from the ponytail plugin (v5.3.2), without its hooks.
  ponytail = pkgs.fetchFromGitHub {
    owner = "DietrichGebert";
    repo = "ponytail";
    rev = "16352ac229eb08a9598dcae48fe9f2b342567d86";
    hash = "sha256-IJlhfkdXI6pMZZCZO7XBRg88LBiNfzc5Gnm4ofGybL8=";
  };

  # Honey (honey-for-devs v1.4.0) without its plugin: the hive agents, the mode
  # hooks and the skills needing neither npx, pip nor the repo's bench/. The
  # PostToolUse hook rewriting Bash output stays out.
  honey = pkgs.fetchFromGitHub {
    owner = "Green-PT";
    repo = "honey-for-devs";
    rev = "cc82b7e7250a8295b4ba556e0aa291d78a9ed38a";
    hash = "sha256-ZYPoMSOjwfYEWMbqHC7XFTDfNtuKQ+ABbQHz+qmuqMk=";
  };
  honeyNode = lib.getExe pkgs.nodejs;
  honeyHook = script: {
    type = "command";
    command = "${honeyNode} ${honey}/hooks/${script}";
  };
  # Skills calling the plugin's scripts get the plugin root and node as store paths.
  honeySkill =
    name:
    pkgs.runCommand "honey-skill-${name}" { pluginRootVar = "\${CLAUDE_PLUGIN_ROOT}"; } ''
      cp -r ${honey}/skills/${name} $out
      chmod -R u+w $out
      if grep -qF "$pluginRootVar" $out/SKILL.md; then
        substituteInPlace $out/SKILL.md \
          --replace-fail "$pluginRootVar" ${honey} \
          --replace-fail '`node ' '`${honeyNode} '
      fi
    '';
  honeyFiles =
    genAttrs' [
      "honey"
      "honey-ccr"
      "honey-compress"
      "honey-debt"
      "honey-design"
      "honey-hive"
      "honey-loop"
      "honey-memory"
      "honey-review"
    ] (name: lib.nameValuePair ".claude/skills/${name}" { source = honeySkill name; })
    // genAttrs' [ "hive-builder" "hive-reviewer" "hive-scout" ] (
      name: lib.nameValuePair ".claude/agents/${name}.md" { source = "${honey}/agents/${name}.md"; }
    );

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
  #
  # Hook commands are store paths, not `~/.claude/hooks/` files or bare names:
  # a container sandbox can hide `~/.claude` and lack the Home Manager profile
  # on PATH while still mounting the host's nix store.
  commonSettings = mergeSettings (lib.importJSON ./settings_common.json) {
    permissions.additionalDirectories = [ wikiRoot ];
    # Packaged rather than `npx`, so rendering needs no route to registry.npmjs.org.
    statusLine = {
      type = "command";
      command = lib.getExe ccstatusline;
    };
    hooks = {
      SessionStart = [
        {
          matcher = "startup|resume|clear|compact";
          hooks = [
            {
              type = "command";
              command = "${lib.getExe pkgs.bash} ${./hooks/wiki-index.sh}";
            }
          ];
        }
        { hooks = [ (honeyHook "honey-session.js") ]; }
      ];
      SubagentStart = [ { hooks = [ (honeyHook "honey-subagent.js") ]; } ];
      UserPromptSubmit = [
        {
          hooks = [
            {
              type = "command";
              command = "${codegraph}/bin/codegraph prompt-hook";
            }
          ];
        }
      ];
    };
  };

  localEnv = (lib.importJSON ./settings_local.json).env;

  # Per-backend env overrides. `cloud` adds nothing (native Anthropic endpoint);
  # `container` talks to the same endpoint from inside a container sandbox.
  # `strata` is a local Strata server, with the timeouts of the local ollama.
  backendEnv = {
    cloud = { };
    container = { };
    local = localEnv;
    strata = localEnv // {
      ANTHROPIC_BASE_URL = "http://127.0.0.1:8080";
      ANTHROPIC_AUTH_TOKEN = "strata";
    };
    hyperion = (lib.importJSON ./settings_hyperion.json).env;
  };

  # Ask rules that must prompt in every backend, bypass included: the GitLab
  # writes that create or mutate merge requests. `settings_common.json` puts
  # them in `permissions.ask`; the container backend keeps only these.
  isGitlabWriteRule =
    rule:
    lib.any (prefix: lib.hasPrefix prefix rule) [
      "Bash(glab api "
      "Bash(glab mr create"
    ];

  # Per-backend rewrite of the merged settings, for what a merge cannot
  # express: removing keys. `container` drops the host-only blocks — the
  # bubblewrap `sandbox` (the container is the boundary, and bubblewrap does
  # not start inside podman) and all `permissions.ask` rules but the GitLab
  # writes (content-scoped ask rules still prompt under bypass) — and makes
  # bypass the default mode. `statusLine` stays: the packaged renderer runs
  # inside the sandbox.
  # Mirrors nixcfg-home's microvm guest.
  finalize = {
    container =
      settings:
      removeAttrs settings [ "sandbox" ]
      // {
        permissions = settings.permissions // {
          ask = lib.filter isGitlabWriteRule (settings.permissions.ask or [ ]);
          defaultMode = "bypassPermissions";
        };
      };
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
    pkgs.writeText "claude-settings-${backend}.json" (
      builtins.toJSON ((finalize.${backend} or lib.id) unified)
    );

  # `claude-<backend>` wrapper pinning the backend's settings and MCP servers.
  wrapperFor =
    backend:
    pkgs.writeShellScriptBin "claude-${backend}" ''
      # `home.profileDirectory` puts ~/.nix-profile on PATH, which the Bash
      # sandbox does not materialize, leaving every Home Manager package
      # unreachable. Prepend the profile directory nix itself manages; the
      # path is absent where home-manager installs through the NixOS module.
      export PATH="$HOME/.local/state/nix/profiles/profile/bin:$PATH"

      ${lib.optionalString (backend != "container") ''
        # The sandbox masks a missing protected path with a `nodev` bind of
        # /dev/null, which opens with EACCES. Started in $HOME, the cwd-only
        # `.gitconfig` mask lands on ~/.gitconfig, which git probes as a global
        # config and aborts on. Naming the XDG file skips that probe. Not in
        # `container`: it drops the `sandbox` block, so no mask exists, the XDG
        # file is absent inside the container, and pinning git there hides the
        # container's own `~/.gitconfig`.
        export GIT_CONFIG_GLOBAL="${config.xdg.configHome}/git/config"
      ''}

      exec ${claude-code}/bin/claude \
        --settings ${settingsFileFor backend} \
        --mcp-config ${mcpConfigFile} \
        "$@"
    '';

  backendType = lib.types.enum [
    "cloud"
    "container"
    "local"
    "strata"
    "hyperion"
  ];
in
{
  options.custom.roles.dev.claudecode = {
    enable = lib.mkEnableOption "claude-code";
    backends = lib.mkOption {
      type = lib.types.listOf backendType;
      default = [
        "cloud"
        "hyperion"
      ];
      description = ''
        Backends to expose as `claude-<backend>` commands. Each generates a
        self-contained settings file passed via `claude --settings`. `cloud`
        uses the native Anthropic endpoint; `container` does too but with the
        host-only settings stripped for a run inside a container sandbox; `local`
        and `hyperion` point at ollama (see settings_local.json /
        settings_hyperion.json); `strata` points at a Strata server on
        127.0.0.1:8080 with the timeouts of `local`.
      '';
    };
    defaultBackend = lib.mkOption {
      type = backendType;
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
    wrapperPackages = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      readOnly = true;
      description = ''
        The generated `claude-<backend>` wrappers keyed by backend, for
        downstream launchers that wrap one of them (a sandbox launcher around
        `container`, say) without matching names in `home.packages`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    custom.roles.dev.claudecode.wrapperPackages = lib.genAttrs cfg.backends wrapperFor;

    assertions = [
      {
        assertion = lib.elem cfg.defaultBackend cfg.backends;
        message = "custom.roles.dev.claudecode.defaultBackend (${cfg.defaultBackend}) must be listed in backends ([ ${lib.concatStringsSep " " cfg.backends} ]).";
      }
    ];

    # The wiki folder below is inert without it; hosts that must not run
    # Syncthing set `custom.roles.syncthing.enable = mkForce false`.
    custom.roles.syncthing.enable = lib.mkDefault true;

    # Agent microVM workspaces hold git checkouts, recoverable from their remotes.
    custom.roles.backup.excludes = [ "${config.home.homeDirectory}/microvm/*/workspace/" ];

    home = {
      shellAliases.claude = "claude-${cfg.defaultBackend}";

      # Opts out of telemetry (codegraph and others) in shells; settings_common.json covers sessions.
      sessionVariables.DO_NOT_TRACK = "1";

      packages =
        with pkgs;
        [
          gh
          unstable.ccusage
          unstable.herdr
        ]
        ++ [
          claude-code
          claude-agent-acp
          ccstatusline
          codegraph
        ]
        ++ lib.attrValues cfg.wrapperPackages
        # Only include seccomp on Linux - macOS uses native sandbox
        ++ lib.optionals isLinux [
          claude-seccomp # sandbox dependency
        ];

      file = {
        # The CodeGraph guidance is shared with opencode's AGENTS.md.
        ".claude/CLAUDE.md".text = lib.concatStringsSep "\n" [
          (builtins.readFile ./CLAUDE.md)
          (builtins.readFile ../codegraph.md)
        ];

        # ccstatusline layout (statusLine command set in commonSettings).
        # Leading git-root-dir widget shows the project name.
        ".config/ccstatusline/settings.json".source = ./ccstatusline.json;

        # Slash commands
        ".claude/commands/wiki.md".source = wikiCommand;

        # Skills directories
        ".claude/skills/commit".source = ./skills/commit;
        ".claude/skills/ollama".source = ./skills/ollama;
        ".claude/skills/ponytail-audit".source = "${ponytail}/skills/ponytail-audit";
        ".claude/skills/ponytail-review".source = "${ponytail}/skills/ponytail-review";
        ".claude/skills/updating-nixcfg".source = ./skills/updating-nixcfg;
      }
      // honeyFiles
      // lib.optionalAttrs isLinux {
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
