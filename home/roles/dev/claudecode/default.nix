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

  llmWiki = config.custom.programs.llm-wiki;

  # Skills cherry-picked from the ponytail plugin (v5.3.3), without its hooks: the
  # plugin is installed only at project/local scope, so a user-scope session has
  # nothing else to fall back on. Only the two with dispatch counters at user
  # scope, plus the mode skill; `ponytail-gain` and `ponytail-debt` were reached
  # through the plugin's own namespaced copies, so seeding them would add entries
  # to every session for skills that never run there.
  ponytail = pkgs.fetchFromGitHub {
    owner = "DietrichGebert";
    repo = "ponytail";
    rev = "96608e078b2d5ea607c5c3b8b5a54d1c1fba6846";
    hash = "sha256-PhPtZbeX2wBp19GtWRy+fV93+fFYZe5S487eXPDl/us=";
  };
  ponytailSkills = [
    "ponytail"
    "ponytail-audit"
    "ponytail-review"
  ];
  ponytailFiles = lib.listToAttrs (
    map (
      name: lib.nameValuePair ".claude/skills/${name}" { source = "${ponytail}/skills/${name}"; }
    ) ponytailSkills
  );

  # Skills from mattpocock/skills (plugin v1.3.1), seeded in place of the
  # mattpocock-skills plugin, which settings_common.json disables. Values are the
  # repo's group directories. The plugin's own `code-review` is left out: a bare
  # skill of that name would collide with the skill claude-code bundles.
  mattpocockSkills = pkgs.fetchFromGitHub {
    owner = "mattpocock";
    repo = "skills";
    rev = "49dd158d1076134a641b33efb035946536778336";
    hash = "sha256-NljCSZNI3sZ+vbCw7pRdrwR7try4BxOFp4gdjuWYtzs=";
  };
  mattpocockFiles =
    lib.mapAttrs'
      (
        name: group:
        lib.nameValuePair ".claude/skills/${name}" {
          source = "${mattpocockSkills}/skills/${group}/${name}";
        }
      )
      {
        domain-modeling = "engineering";
        grill-me = "productivity";
        grill-with-docs = "engineering";
        grilling = "productivity";
        implement-spec = "engineering";
        setup-matt-pocock-skills = "engineering";
        to-spec = "engineering";
        tdd = "engineering";
      };

  securityAudit = pkgs.fetchFromGitHub {
    owner = "cloudflare";
    repo = "security-audit-skill";
    rev = "c1c8a8c1471069fb0e188eeaff69b8e8db6564a8";
    hash = "sha256-oVVACjotkHvllQGxEP8yWaEt4c3GxT0d909TUM5P3NM=";
  };

  # Honey (honey-for-devs v1.4.0), plugin and hooks both off: only
  # `/honey-compress` stays, and it needs nothing from the plugin once
  # `honeySkill` bakes the store paths for `bin/check.js` and node into its SKILL.md.
  honey = pkgs.fetchFromGitHub {
    owner = "Green-PT";
    repo = "honey-for-devs";
    rev = "cc82b7e7250a8295b4ba556e0aa291d78a9ed38a";
    hash = "sha256-ZYPoMSOjwfYEWMbqHC7XFTDfNtuKQ+ABbQHz+qmuqMk=";
  };
  honeyNode = lib.getExe pkgs.nodejs;
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
  honeyFiles = genAttrs' [ "honey-compress" ] (
    name: lib.nameValuePair ".claude/skills/${name}" { source = honeySkill name; }
  );

  # Packaged with jq, since a container sandbox lacks the Home Manager profile on PATH.
  simplifyNudge = pkgs.writeShellApplication {
    name = "simplify-nudge";
    runtimeInputs = [ pkgs.jq ];
    text = builtins.readFile ./hooks/simplify-nudge.sh;
  };
  simplifyNudgeHook = mode: {
    type = "command";
    command = "${lib.getExe simplifyNudge} ${mode}";
  };

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
    permissions.additionalDirectories = [ llmWiki.root ];
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
      ];
      PostToolUse = [
        {
          matcher = "Edit|Write|MultiEdit|NotebookEdit";
          hooks = [ (simplifyNudgeHook "record") ];
        }
      ];
      Stop = [ { hooks = [ (simplifyNudgeHook "stop") ]; } ];
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

  # `container` and the backends listed in `containerBackends` run inside a
  # container sandbox.
  inContainer = backend: backend == "container" || lib.elem backend cfg.containerBackends;

  # Rewrite of a container backend's merged settings, for what a merge cannot
  # express: removing keys. It drops the host-only blocks — the bubblewrap
  # `sandbox` (the container is the boundary, and bubblewrap does not start
  # inside podman) and all `permissions.ask` rules but the GitLab writes
  # (content-scoped ask rules still prompt under bypass) — and makes bypass the
  # default mode. `statusLine` stays: the packaged renderer runs inside the
  # sandbox.
  # Mirrors nixcfg-home's microvm guest.
  finalizeContainer =
    settings:
    removeAttrs settings [ "sandbox" ]
    // {
      permissions = settings.permissions // {
        ask = lib.filter isGitlabWriteRule (settings.permissions.ask or [ ]);
        defaultMode = "bypassPermissions";
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
      builtins.toJSON ((if inContainer backend then finalizeContainer else lib.id) unified)
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

      ${lib.optionalString (!inContainer backend) ''
        # The sandbox masks a missing protected path with a `nodev` bind of
        # /dev/null, which opens with EACCES. Started in $HOME, the cwd-only
        # `.gitconfig` mask lands on ~/.gitconfig, which git probes as a global
        # config and aborts on. Naming the XDG file skips that probe. Not in a
        # container backend: it drops the `sandbox` block, so no mask exists,
        # the XDG file is absent inside the container, and pinning git there
        # hides the container's own `~/.gitconfig`.
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
    containerBackends = lib.mkOption {
      type = lib.types.listOf backendType;
      default = [ ];
      description = ''
        Backends besides `container` that run inside a container sandbox, such
        as `strata` launched through a sandbox launcher. Their settings get the
        `container` rewrite (no `sandbox` block, only the GitLab write `ask`
        rules, `bypassPermissions`) and their wrapper leaves
        `GIT_CONFIG_GLOBAL` unset.
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
    custom = {
      programs = {
        herdr.enable = true;
        llm-wiki.enable = true;
      };

      roles = {
        dev.claudecode.wrapperPackages = lib.genAttrs cfg.backends wrapperFor;

        # Agent microVM workspaces hold git checkouts, recoverable from their remotes.
        backup.excludes = [ "${config.home.homeDirectory}/microvm/*/workspace/" ];
      };
    };

    assertions = [
      {
        assertion = lib.elem cfg.defaultBackend cfg.backends;
        message = "custom.roles.dev.claudecode.defaultBackend (${cfg.defaultBackend}) must be listed in backends ([ ${lib.concatStringsSep " " cfg.backends} ]).";
      }
    ];

    home = {
      shellAliases.claude = "claude-${cfg.defaultBackend}";

      # Opts out of telemetry (codegraph and others) in shells; settings_common.json covers sessions.
      sessionVariables.DO_NOT_TRACK = "1";

      packages =
        with pkgs;
        [
          gh
          unstable.ccusage
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
        ".claude/commands/wiki.md".source = llmWiki.command;

        # Skills directories
        ".claude/skills/commit".source = ./skills/commit;
        ".claude/skills/herdr".source = config.custom.programs.herdr.skill;
        ".claude/skills/ollama".source = ./skills/ollama;
        ".claude/skills/security-audit".source = "${securityAudit}/skills/security-audit";
        ".claude/skills/updating-nixcfg".source = ./skills/updating-nixcfg;
      }
      // ponytailFiles
      // honeyFiles
      // mattpocockFiles
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
  };
}
