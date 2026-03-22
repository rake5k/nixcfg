{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.roles.dev.claudecode;
in
{
  options.custom.roles.dev.claudecode = {
    enable = lib.mkEnableOption "claude-code";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      unstable.claude-code
    ];
  };
}
