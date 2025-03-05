{
  lib,
  stdenv,
  fetchFromGitLab,
}:

stdenv.mkDerivation rec {
  pname = "protopedal";
  version = "2.5";

  src = fetchFromGitLab {
    owner = "openirseny";
    repo = "protopedal";
    rev = "release-${version}";
    sha256 = "0l9y7b2rawnpyp10h7rji7x7g8hpjch4g9a2b8fa44w4zakfv3nw";
  };

  buildPhase = ''
    make
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp protopedal $out/bin/
  '';

  meta = with lib; {
    description = "Compatibility tool for sim racing pedals and force feedback steering wheels.";
    license = licenses.eupl12;
    longDescription = ''
      Compatibility tool for sim racing pedals and force feedback steering wheels.
      Helps with wheel and pedal detection by creating virtual devices with extended capabilities.
      Facilitates merging devices, range adjustments, custom curves, button to axis and axis to button mappings.
    '';
    homepage = "https://gitlab.com/openirseny/protopedal";
    platforms = platforms.linux;
    maintainers = [ maintainers.rake5k ];
    mainProgram = "protopedal";
  };
}
