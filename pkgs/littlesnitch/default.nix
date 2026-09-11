# Little Snitch for Linux.
#
# The GitHub repository holds only the Open Source parts (the eBPF crate, the
# shared crate and the web UI assets); the daemon itself is proprietary
# freeware and is not buildable from it. Upstream therefore publishes no
# release assets on GitHub — the binaries come from obdev.at.
#
# Of the four package formats offered there, the musl tarball is the one that
# fits a Nix build: it is statically linked, so nothing needs patchelf. The
# trade-off is that it carries no libpam, which rules out the web UI's
# `system_account` authentication; put a reverse proxy in front instead.
{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  # Checksums are upstream's own, from
  # https://www.obdev.at/downloads/littlesnitch-linux/littlesnitch-1.1.0.hashes.txt
  variants = {
    x86_64-linux = {
      arch = "amd64";
      hash = "sha256-8dRDNf3qer0/C9QYGXuIpl2QJKsJlYDnF5lRFIvQfOE=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-n6OH3jrU1VEGZblK4xVvMIKUxnP2sWkpB6xutilK7qM=";
    };
  };

  inherit (stdenvNoCC.hostPlatform) system;

  variant = variants.${system} or (throw "littlesnitch: no binary release for ${system}");
in

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "littlesnitch";
  version = "1.1.0";

  src = fetchurl {
    url = "https://www.obdev.at/downloads/littlesnitch-linux/littlesnitch-${finalAttrs.version}-${variant.arch}-linux-musl.tar.gz";
    inherit (variant) hash;
  };

  sourceRoot = "littlesnitch-${finalAttrs.version}";

  # The eBPF programs and the web UI are embedded in the binary and extracted
  # to /var/lib/littlesnitch at every start; stripping must not touch them.
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm0755 usr/bin/littlesnitch $out/bin/littlesnitch
    install -Dm0644 usr/share/doc/littlesnitch/copyright \
      $out/share/doc/littlesnitch/copyright

    runHook postInstall
  '';

  meta = {
    description = "Network monitor showing which programs connect where";
    longDescription = ''
      Little Snitch for Linux watches outgoing and incoming connections with
      eBPF and attributes them to the program that made them. Rules and
      blocklists are managed in a web interface served by the daemon, on
      127.0.0.1:3031 by default.

      The daemon needs a kernel of at least 6.12, built with BTF and
      CONFIG_FUNCTION_TRACER.
    '';
    homepage = "https://obdev.at/products/littlesnitch-linux";
    downloadPage = "https://www.obdev.at/products/littlesnitch-linux/download.html";
    license = lib.licenses.unfreeRedistributable;
    maintainers = with lib.maintainers; [ rake5k ];
    platforms = lib.attrNames variants;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "littlesnitch";
  };
})
