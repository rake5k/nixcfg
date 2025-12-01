{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.custom.users.christian.git;

  credentialHelper =
    if pkgs.stdenv.isDarwin then
      "${pkgs.gitFull}/share/git/contrib/credential/osxkeychain/git-credential-osxkeychain"
    else
      "${pkgs.gitFull}/share/git/contrib/credential/libsecret/git-credential-libsecret";

  inherit (lib) mkDefault mkEnableOption mkIf;

in

{
  options = {
    custom.users.christian.git = {
      enable = mkEnableOption "Git";
    };
  };

  config = mkIf cfg.enable {
    custom.programs.lazygit.enable = true;

    home.packages = with pkgs; [ git-crypt ];

    programs.difftastic = {
      enable = true;
      git.enable = true;
    };

    programs.git = {
      enable = true;
      package = pkgs.gitFull;
      lfs.enable = true;
      signing.key = "630966F4";

      settings = {
        user = {
          name = "Christian Harke";
          email = mkDefault "christian@harke.ch";
        };

        alias = {
          co = "checkout";
          cp = "cherry-pick";
          changes = "diff --name-status -r";
          d = "diff";
          dh = "diff HEAD";
          ds = "diff --staged";
          dw = "diff --color-words";
          fu = "commit -a --fixup=HEAD";
          ignored = "ls-files --exclude-standard --ignored --others";
          lg = "log --graph --full-history --all --color --pretty=format:'%x1b[33m%h%x09%C(blue)(%ar)%C(reset)%x09%x1b[32m%d%x1b[0m%x20%s%x20%C(dim white)-%x20%G?%x20%an%C(reset)'";
          rc = "rebase --continue";
          ri = "rebase --interactive --autosquash";
          rs = "rebase --skip";
          s = "status";
          ss = "status -s";
        };

        credential.helper = credentialHelper;
      };

      ignores = [
        # Taken from https://github.com/github/gitignore

        # Global/Linux
        #

        "*~"

        # temporary files which can be created if a process still has a handle open of a deleted file
        ".fuse_hidden*"

        # KDE directory preferences
        ".directory"

        # Linux trash folder which might appear on any partition or disk
        ".Trash-*"

        # .nfs files are created when an open file is removed but is still being accessed
        ".nfs*"

        # Global/OSX
        ".DS_Store"

        # Community/Nix
        #

        # Direnv
        ".direnv/"

        # Ignore build outputs from performing a nix-build or `nix build` command
        "result"
        "result-*"

        # Global/Archives
        #

        # It's better to unpack these files and commit the raw source because
        # git has its own built in compression methods.
        "*.7z"
        "*.jar"
        "*.rar"
        "*.zip"
        "*.gz"
        "*.gzip"
        "*.tgz"
        "*.bzip"
        "*.bzip2"
        "*.bz2"
        "*.xz"
        "*.lzma"
        "*.cab"
        "*.xar"

        # Packing-only formats
        "*.iso"
        "*.tar"

        # Package management formats
        "*.dmg"
        "*.xpi"
        "*.gem"
        "*.egg"
        "*.deb"
        "*.rpm"
        "*.msi"
        "*.msm"
        "*.msp"
        "*.txz"

        # Global/Backup
        #

        "*.bak"
        "*.gho"
        "*.ori"
        "*.orig"
        "*.tmp"

        # Global/Diff
        #

        "*.patch"
        "*.diff"

        # Global/Ansible
        #

        "*.retry"

        # Global/Jetbrains
        #

        # Covers JetBrains IDEs: IntelliJ, RubyMine, PhpStorm, AppCode, PyCharm, CLion, Android Studio, WebStorm and Rider
        # Reference: https://intellij-support.jetbrains.com/hc/en-us/articles/206544839

        # User-specific stuff
        ".idea/**/workspace.xml"
        ".idea/**/tasks.xml"
        ".idea/**/usage.statistics.xml"
        ".idea/**/dictionaries"
        ".idea/**/shelf"

        # AWS User-specific
        ".idea/**/aws.xml"

        # Generated files
        ".idea/**/contentModel.xml"

        # Sensitive or high-churn files
        ".idea/**/dataSources/"
        ".idea/**/dataSources.ids"
        ".idea/**/dataSources.local.xml"
        ".idea/**/sqlDataSources.xml"
        ".idea/**/dynamic.xml"
        ".idea/**/uiDesigner.xml"
        ".idea/**/dbnavigator.xml"

        # Gradle
        ".idea/**/gradle.xml"
        ".idea/**/libraries"

        # Gradle and Maven with auto-import
        # When using Gradle or Maven with auto-import, you should exclude module files,
        # since they will be recreated, and may cause churn.  Uncomment if using
        # auto-import.
        ".idea/artifacts"
        ".idea/compiler.xml"
        ".idea/jarRepositories.xml"
        ".idea/modules.xml"
        ".idea/*.iml"
        ".idea/modules"
        "*.iml"
        "*.ipr"

        # CMake
        "cmake-build-*/"

        # Mongo Explorer plugin
        ".idea/**/mongoSettings.xml"

        # File-based project format
        "*.iws"

        # IntelliJ
        "out/"

        # mpeltonen/sbt-idea plugin
        ".idea_modules/"

        # JIRA plugin
        "atlassian-ide-plugin.xml"

        # Cursive Clojure plugin
        ".idea/replstate.xml"

        # SonarLint plugin
        ".idea/sonarlint/"

        # Crashlytics plugin (for Android Studio and IntelliJ)
        "com_crashlytics_export_strings.xml"
        "crashlytics.properties"
        "crashlytics-build.properties"
        "fabric.properties"

        # Editor-based Rest Client
        ".idea/httpRequests"

        # Android studio 3.1+ serialized cache file
        ".idea/caches/build_file_checksums.ser"

        # Global/LibreOffice
        #

        # LibreOffice locks
        ".~lock.*#"

        # Global/SBT
        #

        # Simple Build Tool
        # http://www.scala-sbt.org/release/docs/Getting-Started/Directories.html#configuring-version-control

        "dist/*"
        "target/"
        "lib_managed/"
        "src_managed/"
        "project/boot/"
        "project/plugins/project/"
        ".history"
        ".cache"
        ".lib/"

        # Global/Vagrant
        #

        # General
        ".vagrant/"

        # Log files (if you are creating logs in debug mode, uncomment this)
        "*.log"

        # Global/Vim
        #

        # Swap
        "[._]*.s[a-v][a-z]"
        "!*.svg" # comment out if you don't need vector files
        "[._]*.sw[a-p]"
        "[._]s[a-rt-v][a-z]"
        "[._]ss[a-gi-z]"
        "[._]sw[a-p]"

        # Session
        "Session.vim"
        "Sessionx.vim"

        # Temporary
        ".netrwhist"
        "*~"
        # Auto-generated tag files
        "tags"
        # Persistent undo
        "[._]*.un~"

        # Global/VisualStudioCode
        #

        ".vscode/*"
        "!.vscode/settings.json"
        "!.vscode/tasks.json"
        "!.vscode/launch.json"
        "!.vscode/extensions.json"
        "!.vscode/*.code-snippets"

        # Local History for Visual Studio Code
        ".history/"

        # Built Visual Studio Code Extensions
        "*.vsix"
      ];
    };
  };
}
