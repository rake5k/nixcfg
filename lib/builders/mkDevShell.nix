{
  pkgs,
  customLib,
  args,
  ...
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # banner printing on enter
    figlet
    lolcat

    nix-tree
    nixfmt
    shellcheck
    statix
  ];
  shellHook = ''
    figlet ${args.flake.name} | lolcat --freq 0.5
    ${customLib.pre-commit-checks.shellHook}
  '';
}
