{
  stdenv,
  fetchFromGitHub,
  kernel,
  linuxConsoleTools,
}:

let
  moduledir = "lib/modules/${kernel.modDirVersion}/kernel/drivers/hid";
in
stdenv.mkDerivation rec {
  pname = "hid-fanatecff";
  version = "0.1.2";
  name = "hid-fanatecff-${version}-${kernel.modDirVersion}";

  src = fetchFromGitHub {
    owner = "gotzl";
    repo = "hid-fanatecff";
    rev = version;
    sha256 = "twDbjX0p/A18L2x7eS2hyneuQq7rLMxTBT/GfTdweAE=";
  };

  hardeningDisable = [
    "pic"
    "format"
  ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  patchPhase = ''
    mkdir -p $out/lib/udev/rules.d
    mkdir -p $out/${moduledir}
    substituteInPlace Makefile --replace "/etc/udev/rules.d" "$out/lib/udev/rules.d"
    substituteInPlace fanatec.rules --replace "/usr/bin/evdev-joystick" "${linuxConsoleTools}/bin/evdev-joystick" --replace "/bin/sh" "${stdenv.shell}"
    sed -i '/depmod/d' Makefile
  '';

  makeFlags = [
    "KVERSION=${kernel.modDirVersion}"
    "KERNEL_SRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "MODULEDIR=$(out)/${moduledir}"
  ];
}
