{
  lib,
  pkgs,
  inputs,
}:

inputs.flake-commons.lib {
  inherit lib pkgs;
  flake = inputs.self;
}
// {
  # Wraps all binary files of the given `pkg` with `nixGL`
  nixGLWrap =
    pkg:
    pkgs.runCommand "${pkg.name}-nixgl-wrapped" { meta.mainProgram = pkg.name; } ''
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

  # Wraps the main program of the given `pkg` with `nixGL` and names the wrapper script as given `bin`
  nixGLWrap' =
    pkg: bin:
    pkgs.runCommand "${pkg.name}-nixgl-wrapped" { meta.mainProgram = bin; } ''
      mkdir $out
      ln -s ${pkg}/* $out
      rm $out/bin
      mkdir $out/bin
      wrapped_bin=$out/bin/${bin}
      echo "#!${pkgs.bash}/bin/bash" >> $wrapped_bin
      echo "exec ${pkgs.lib.getExe pkgs.nixgl.auto.nixGLDefault} ${pkgs.lib.getExe pkg} \"\$@\"" >> $wrapped_bin
      chmod +x $wrapped_bin
    '';
}
