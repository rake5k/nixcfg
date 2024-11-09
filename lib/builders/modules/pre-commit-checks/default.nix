{ flake, system, pkgs }:

let

  inherit (flake) inputs;
  inherit (pkgs) lib;
  pre-commit-hooks = inputs.pre-commit-hooks.lib.${system};

in

pre-commit-hooks.run {
  src = ./.;
  hooks = {
    # Nix
    nixfmt-rfc-style.enable = true;
    statix.enable = true;

    # Shell
    shellcheck.enable = true;

    # Misc
    markdownlint = {
      enable = true;
      # https://github.com/DavidAnson/markdownlint/blob/main/schema/.markdownlint.jsonc
      settings.configuration = lib.importJSON "${flake}/.markdownlint.json";
    };

    yamllint = {
      enable = true;
      settings = {
        configPath = "${flake}/.yamllint";
        strict = false;
      };
    };
  };
}
