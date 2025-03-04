{
  stdenv,
  fetchFromGitHub,
  kernel,
  linuxConsoleTools,
  runtimeShell,
}:

let
  moduledir = "lib/modules/${kernel.version}/kernel/drivers/hid";
in
stdenv.mkDerivation rec {
  pname = "hid-fanatecff";
  version = "0.0.2";
  name = "hid-fanatecff-${version}-${kernel.version}";

  src = fetchFromGitHub {
    owner = "gotzl";
    repo = "hid-fanatecff";
    rev = "next";
    hash = "sha256-FZc69a2joiCi8pPxeJxhORaqa/ABRecPqDhDCc2GwL0=";
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
    substituteInPlace fanatec.rules \
      --replace "/bin/sh" "${runtimeShell}" \
      --replace "/usr/bin/evdev-joystick" "${linuxConsoleTools}/bin/evdev-joystick" \
      --replace "GROUP:=\"plugdev\"" "TAG+=\"uaccess\""
    sed -i '/depmod/d' Makefile
  '';

  makeFlags = [
    "KVERSION=${kernel.modDirVersion}"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "MODULEDIR=$(out)/${moduledir}"
  ];
}
