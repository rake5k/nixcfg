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
    mkNtfyCommand =
      secretsCfg: body:
      let
        ntfyTopic = "chris-alerts";

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
  }
)
