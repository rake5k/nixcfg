{
  lib,
  fetchurl,
  makeWrapper,
  nodejs,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ccstatusline";
  version = "2.2.29";

  # The npm tarball ships the bundled `dist/ccstatusline.js` (`bun build
  # --target=node`), so there is nothing to compile and no dependency tree to
  # pin — upstream publishes no package-lock.json, which rules out
  # `buildNpmPackage`.
  src = fetchurl {
    url = "https://registry.npmjs.org/ccstatusline/-/ccstatusline-${finalAttrs.version}.tgz";
    hash = "sha256-3FgL4V0EN4cR8uFfDXZ4zhSqDct7IOVXqJsNlCoGeeU=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm444 dist/ccstatusline.js $out/lib/ccstatusline/ccstatusline.js
    makeWrapper ${nodejs}/bin/node $out/bin/ccstatusline \
      --add-flags $out/lib/ccstatusline/ccstatusline.js

    runHook postInstall
  '';

  meta = {
    description = "Customizable status line formatter for Claude Code";
    homepage = "https://github.com/sirmalloc/ccstatusline";
    license = lib.licenses.mit;
    mainProgram = "ccstatusline";
    platforms = lib.platforms.all;
  };
})
