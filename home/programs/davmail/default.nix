{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.programs.davmail;

  configType =
    with types;
    oneOf [
      (attrsOf configType)
      str
      int
      bool
    ]
    // {
      description = "davmail config type (str, int, bool or attribute set thereof)";
    };

  toStr = val: if isBool val then boolToString val else toString val;

  linesForAttrs =
    attrs:
    concatMap (
      name:
      let
        value = attrs."${name}";
      in
      if isAttrs value then
        map (line: name + "." + line) (linesForAttrs value)
      else
        [ "${name}=${toStr value}" ]
    ) (attrNames attrs);

  configFile = pkgs.writeText "davmail.properties" (concatStringsSep "\n" (linesForAttrs cfg.config));

in

{
  options.custom.programs.davmail = {
    enable = mkEnableOption "davmail, an MS Exchange gateway";

    url = mkOption {
      type = types.str;
      description = "Outlook Web Access URL to access the exchange server, i.e. the base webmail URL.";
      example = "https://outlook.office365.com/EWS/Exchange.asmx";
    };

    config = mkOption {
      type = configType;
      default = { };
      description = ''
        Davmail configuration. Refer to
        <link xlink:href="http://davmail.sourceforge.net/serversetup.html"/>
        and <link xlink:href="http://davmail.sourceforge.net/advanced.html"/>
        for details on supported values.
      '';
      example = literalExpression ''
        {
          davmail.allowRemote = true;
          davmail.imapPort = 55555;
          davmail.bindAddress = "10.0.1.2";
          davmail.smtpSaveInSent = true;
          davmail.folderSizeLimit = 10;
          davmail.caldavAutoSchedule = false;
          log4j.logger.rootLogger = "DEBUG";
        }
      '';
    };
  };

  config = mkIf cfg.enable {

    custom.programs.davmail.config = {
      davmail = mapAttrs (_: mkDefault) {
        server = true;
        disableUpdateCheck = true;
        logFilePath = config.xdg.dataHome + "/davmail/davmail.log";
        logFileSize = "1MB";
        mode = "auto";
        inherit (cfg) url;
        caldavPort = 1080;
        imapPort = 1143;
        ldapPort = 1389;
        popPort = 1110;
        smtpPort = 1025;
      };
      log4j = {
        logger = {
          davmail = mkDefault "WARN";
          httpclient.wire = mkDefault "WARN";
          org.apache.commons.httpclient = mkDefault "WARN";
        };
        rootLogger = mkDefault "WARN";
      };
    };

    systemd.user.services.davmail = {
      Unit = {
        Description = "DavMail POP/IMAP/SMTP Exchange Gateway";
        After = [ "network.target" ];
      };

      Service = {
        Type = "simple";
        Environment = "PATH=${pkgs.davmail}/bin:${pkgs.coreutils}/bin";
        ExecStart = "${pkgs.davmail}/bin/davmail ${configFile}";
        Restart = "on-failure";
        LogsDirectory = "davmail";
      };

      Install = {
        WantedBy = [ "vdirsyncer-oneshot.timer" ];
      };
    };

    home.packages = [ pkgs.davmail ];
  };
}
