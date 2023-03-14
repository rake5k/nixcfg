{ inputs }:

let

  forEachSystem =
    let
      inherit (inputs.flake-utils.lib.system) aarch64-linux x86_64-linux;
    in
    inputs.nixpkgs.lib.genAttrs [
      aarch64-linux
      x86_64-linux
    ];

  pkgsFor = forEachSystem (system: import ./nixpkgs.nix { inherit inputs system; });
  customLibFor = forEachSystem (system:
    let
      pkgs = pkgsFor."${system}";
    in
    inputs.flake-commons.lib
      {
        inherit (inputs.nixpkgs) lib;
        inherit pkgs;
        rootPath = inputs.self;
      } // {
      nixGLWrap = pkg: pkgs.runCommand "${pkg.name}-nixgl-wrapper" { } ''
        mkdir $out
        ln -s ${pkg}/* $out
        rm $out/bin
        mkdir $out/bin
        for bin in ${pkg}/bin/*; do
          wrapped_bin=$out/bin/$(basename $bin)
          echo "#!${pkgs.bash}/bin/bash" >> $wrapped_bin
          echo "exec ${pkgs.lib.getExe pkgs.nixgl.auto.nixGLDefault} $bin \"\$@\"" >> $wrapped_bin
          chmod +x $wrapped_bin
        done
      '';
    });

  homeModulesFor = forEachSystem (system:
    let
      customLib = customLibFor.${system};
    in
    [
      inputs.homeage.homeManagerModules.homeage
      inputs.nix-index-database.hmModules.nix-index

      {
        lib.custom = customLib;
      }
    ]
    ++ customLib.getRecursiveDefaultNixFileList ../home
    ++ customLib.getRecursiveDefaultNixFileList "${inputs.self}/home"
  );

  wrapper = builder: system: name: args:
    inputs.nixpkgs.lib.nameValuePair
      name
      (import builder {
        inherit inputs system name args;
        pkgs = pkgsFor."${system}";
        customLib = customLibFor."${system}";
        homeModules = homeModulesFor."${system}";
      });

  simpleWrapper = builder: system: name: wrapper builder system name { };

in

{
  inherit forEachSystem;

  mkHome = simpleWrapper ./builders/mkHome.nix;
  mkNixos = simpleWrapper ./builders/mkNixos.nix;
  mkApp = wrapper ./builders/mkApp.nix;
  mkCheck = wrapper ./builders/mkCheck.nix;
  getDevShell = name: forEachSystem (system: inputs.self.devShells."${system}"."${name}");
  mkDevShell = wrapper ./builders/mkDevShell.nix;
  mkShellCheck = pkgs: ''
    shopt -s globstar
    echo 'Running shellcheck...'
    ${pkgs.lib.getExe pkgs.shellcheck} --check-sourced --enable all --external-sources --shell bash ${./.}/**/*.sh
  '';
}
