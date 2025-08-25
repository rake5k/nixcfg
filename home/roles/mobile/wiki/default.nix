{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.roles.mobile.wiki;

  inherit (lib)
    getExe
    hm
    mkEnableOption
    mkIf
    ;

in

{
  options = {
    custom.roles.mobile.wiki = {
      enable = mkEnableOption "Mobile wiki setup";
    };
  };

  config = mkIf cfg.enable {
    home.activation.configureNotesGit = hm.dag.entryAfter [ "symlinkStorageDocuments" ] ''
      DOCS_SYMLINK="$HOME/Documents"
      if [[ ! -L "$DOCS_SYMLINK" ]]; then
        echo "Error: docs symlink does not exist"
        exit 1
      fi

      NOTES_DIR="$DOCS_SYMLINK/notes/home"
      if [[ ! -d "$NOTES_DIR" ]]; then
        $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$NOTES_DIR"
      fi

      pushd "$NOTES_DIR"
      $DRY_RUN_CMD ${getExe pkgs.git} config --local user.email "logseq@harke.ch"
      $DRY_RUN_CMD ${getExe pkgs.git} config --local core.sshCommand "ssh -i ~/.ssh/id_logseq"
    '';

    programs.git.extraConfig = {
      safe.directory = "/storage/emulated/0/Documents/notes/home";
    };
  };
}
