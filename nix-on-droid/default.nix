{ config, lib, pkgs, homeModules, inputs, ... }:

let

  mkUserConfigPath = host: "${inputs.self}/hosts/${host}/home-nix-on-droid.nix";

in

{
  environment = {
    #etcBackupExtension = ".nod-bak";
    #motd = null;

    packages = with pkgs; [
      git
    ];
  };

  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    sharedModules = homeModules;

    config = mkUserConfigPath "nix-on-droid";
  };

  nix.package = pkgs.nix;

  # FIXME: update when released
  system.stateVersion = "22.11";

  terminal.font =
    let
      fontPackage = pkgs.nerdfonts.override {
        fonts = [ "VictorMono" ];
      };
      fontPath = "/share/fonts/truetype/NerdFonts/VictorMonoNerdFont-Regular.ttf";
    in
    fontPackage + fontPath;

  time.timeZone = "Europe/Zurich";

  user.shell = "${pkgs.zsh}/bin/zsh";
}
