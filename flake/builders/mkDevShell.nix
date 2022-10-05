{ pkgs, name, system, args, ... }:

let

  packagesFn = args.packages or (pkgs: [ ]);
  checksShellHookFn = args.checksShellHook or (system: "");
  customShellHookFn = args.customShellHook or (pkgs: { });

in

pkgs.mkShell {
  inherit name;
  buildInputs = with pkgs; [
    # banner printing on enter
    figlet
    lolcat
  ] ++ (packagesFn pkgs);
  shellHook = ''
    figlet ${name} | lolcat --freq 0.5
  ''
  + (checksShellHookFn system)
  + (customShellHookFn pkgs);
}
