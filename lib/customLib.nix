{
  lib,
  pkgs,
  inputs,
}:

inputs.flake-commons.lib {
  inherit lib pkgs;
  flake = inputs.self;
}
// (
  let
    inherit (lib) getExe;
  in
  rec {
    ntfyTokenSecret = "ntfy-token";
    ntfyUrlSecret = "ntfy-url";
    ntfyTopic = "chris-alerts";
    mkNtfyCommand =
      secretsCfg: body:
      let
        jsonBody = builtins.toJSON (body // { topic = ntfyTopic; });
        bodyFile = pkgs.writeText "ntfyBody" jsonBody;
      in
      ''
        ${getExe pkgs.curl} \
          -H "Authorization:Bearer $(${pkgs.coreutils}/bin/cat ${secretsCfg.${ntfyTokenSecret}.path})" \
          -H "Markdown: yes" \
          -H "Content-Type: application/json" \
          -d @'${bodyFile}' \
          "$(${pkgs.coreutils}/bin/cat ${secretsCfg.${ntfyUrlSecret}.path})"
      '';

    mkWritableFile = config: name: opts: {
      "${name}.hm-init" = opts // {
        onChange = ''
          rm -f ${config.home.file}/${name}
          cp ${config.home.file}/${name}.hm-init ${config.home.file}/${name}
          chmod u+w ${config.home.file}/${name}
        '';
      };
    };

    mkWritableConfigFile = config: name: opts: {
      "${name}.hm-init" = opts // {
        onChange = ''
          rm -f ${config.xdg.configHome}/${name}
          cp ${config.xdg.configHome}/${name}.hm-init ${config.xdg.configHome}/${name}
          chmod u+w ${config.xdg.configHome}/${name}
        '';
      };
    };
  }
)
