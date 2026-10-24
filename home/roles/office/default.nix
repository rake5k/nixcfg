{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.office;

in

{
  options = {
    custom.roles.office = {
      enable = mkEnableOption "Office";
    };
  };

  config = mkIf cfg.enable {
    custom.roles.fonts.enable = true;

    home.packages =
      with pkgs;
      [ reveal-md ]
      ++ optionals pkgs.stdenv.hostPlatform.isLinux [
        libreoffice
        openjdk
      ];

    xdg.mimeApps.defaultApplications =
      genAttrs [
        "application/msword"
        "application/rtf"
        "application/vnd.oasis.opendocument.text"
        "application/vnd.oasis.opendocument.text-flat-xml"
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        "application/vnd.openxmlformats-officedocument.wordprocessingml.template"
      ] (_: "writer.desktop")
      // genAttrs [
        "application/vnd.ms-excel"
        "application/vnd.oasis.opendocument.spreadsheet"
        "application/vnd.oasis.opendocument.spreadsheet-flat-xml"
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        "application/vnd.openxmlformats-officedocument.spreadsheetml.template"
        "text/csv"
      ] (_: "calc.desktop")
      // genAttrs [
        "application/vnd.ms-powerpoint"
        "application/vnd.oasis.opendocument.presentation"
        "application/vnd.oasis.opendocument.presentation-flat-xml"
        "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        "application/vnd.openxmlformats-officedocument.presentationml.slideshow"
        "application/vnd.openxmlformats-officedocument.presentationml.template"
      ] (_: "impress.desktop");
  };
}
