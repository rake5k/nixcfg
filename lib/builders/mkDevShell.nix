{ pkgs, system, args, ... }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # banner printing on enter
    figlet
    lolcat

    nix-tree
    nixpkgs-fmt
    shellcheck
    statix
  ];
  shellHook = ''
    figlet ${args.flake.name} | lolcat --freq 0.5
  '' +
  args.flake.checks."${system}".pre-commit-check.shellHook;
}
