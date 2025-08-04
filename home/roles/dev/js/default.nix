{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.dev.js;

  inherit (pkgs.stdenv) isLinux;

in

{
  options = {
    custom.roles.dev.js = {
      enable = mkEnableOption "Javascript";
    };
  };

  config = mkIf cfg.enable {
    custom = {
      programs.firefox = mkIf config.custom.programs.firefox.enable {
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          react-devtools
          vue-js-devtools
        ];
      };
    };

    home.packages = optionals isLinux [
      pkgs.spidermonkey_128 # REPL
    ];
  };
}
