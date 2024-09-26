{ flake, pkgs }:

{
  # Nix

  deadnix = pkgs.runCommand "check-deadnix"
    { buildInputs = [ pkgs.deadnix ]; }
    ''
      mkdir $out
      deadnix --fail ${flake}
    '';

  nixfmt = pkgs.runCommand "check-nixfmt"
    { buildInputs = [ pkgs.nixpkgs-fmt ]; }
    ''
      mkdir $out
      nixpkgs-fmt --check ${flake}
    '';

  statix = pkgs.runCommand "check-statix"
    { buildInputs = [ pkgs.statix ]; }
    ''
      mkdir $out
      statix check ${flake}
    '';

  # Shell

  shellcheck = pkgs.runCommand "check-shellcheck"
    { buildInputs = [ pkgs.shellcheck ]; }
    ''
      mkdir $out
      cd ${flake}
      IFS=$'\n'
      for file in $(find . -name '*.sh' -type f); do shellcheck $file; done;
    '';

  # Misc

  markdownlint = pkgs.runCommand "check-markdownlint"
    { buildInputs = [ pkgs.unstable.markdownlint-cli ]; }
    ''
      mkdir $out
      cd ${flake}
      markdownlint .
    '';

  yamllint = pkgs.runCommand "check-yamllint"
    { buildInputs = [ pkgs.yamllint ]; }
    ''
      mkdir $out
      cd ${flake}
      yamllint .
    '';
}
