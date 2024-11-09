{ pkgs, system, args, ... }:

let

  preCommitShellHook = (import ./modules/pre-commit-checks {
    inherit system pkgs;
    inherit (args) flake;
  }).shellHook;

in

pkgs.mkShell {
  buildInputs = with pkgs; [
    # banner printing on enter
    figlet
    lolcat

    nix-tree
    nixfmt-rfc-style
    shellcheck
    statix
  ];
  shellHook = ''
    figlet ${args.flake.name} | lolcat --freq 0.5
    ${preCommitShellHook}
  '';
}
