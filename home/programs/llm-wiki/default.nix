{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.programs.llm-wiki;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  root = "${config.home.homeDirectory}/Documents/notes/claude";

  # wiki.patch carries the local changes (Syncthing conflict copies, env-expanded memory paths).
  llm-wiki = pkgs.applyPatches {
    name = "llm-wiki";
    src = pkgs.fetchFromGitHub {
      owner = "rake5k";
      repo = "llm-wiki";
      rev = "c23e3fb23a0f479fefd2a7fb765045494115a0ba";
      hash = "sha256-UPADIT+xXhibgHG2MeZmjqxZuGJ596+dDKA/GXhG7Wc=";
    };
    patches = [ ./wiki.patch ];
  };

  # llm-wiki's root skill, copied the way its README describes: the plugin placeholders become the
  # wiki root and the source tree (`/wiki setup` reads `templates/` there), `/llm-wiki` becomes `/wiki`.
  command =
    pkgs.runCommand "wiki.md"
      {
        wikiRootVar = "\${user_config.wiki_path}";
        pluginRootVar = "\${CLAUDE_PLUGIN_ROOT}";
      }
      ''
        substitute ${llm-wiki}/SKILL.md $out \
          --replace-fail "$wikiRootVar" ${lib.escapeShellArg root} \
          --replace-fail "$pluginRootVar" ${llm-wiki} \
          --replace-fail 'name: llm-wiki' 'name: wiki' \
          --replace-fail /llm-wiki /wiki
      '';

in

{
  options = {
    custom.programs.llm-wiki = {
      enable = mkEnableOption "the llm-wiki L2 knowledge base";

      root = mkOption {
        type = types.str;
        readOnly = true;
        default = root;
        description = "Wiki root (Logseq graph) that `/wiki` reads and writes.";
      };

      command = mkOption {
        type = types.path;
        readOnly = true;
        default = command;
        description = ''
          The `/wiki` command file, for the coding agents to link into their commands directory.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # The wiki folder below is inert without it; hosts that must not run
    # Syncthing set `custom.roles.syncthing.enable = mkForce false`.
    custom.roles.syncthing.enable = lib.mkDefault true;

    # Synced through hyperion. `.git` stays local (per-device .stignore);
    # `maxConflicts = 1` keeps a single copy of a lost race instead of a growing
    # pile of conflict files.
    services.syncthing.settings.folders.LogseqClaude = {
      enable = true;
      devices = [
        config.services.syncthing.settings.devices.hyperion.name
      ];
      id = "oce6r-2p1ft";
      maxConflicts = 1;
      path = root;
    };
  };
}
