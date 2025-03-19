{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.custom.roles.gaming.simracing;

  inherit (lib) getExe;
  inherit (pkgs) callPackage writeShellApplication;

  fanatecff = config.boot.kernelPackages.callPackage ../../../../pkgs/hid-fanatecff { };
  protopedal = callPackage ../../../../pkgs/protopedal { };

  vrsPedalsVendor = "0483";
  vrsPedalsProduct = "A3BF";
  vrsPedalsSetupScript = "vrs-pedal-setup";
  vrsPedalsSetup = writeShellApplication {
    name = vrsPedalsSetupScript;
    runtimeInputs = [
      pkgs.linuxConsoleTools
      protopedal
    ];
    text = ''
      #!/bin/sh

      if [ -z "$1" ]; then
        echo "Device not specified"
        exit 1
      fi

      # calibration properties
      # event codes are stated in /usr/include/linux/input-event-codes.h
      DEVICE="$1"
      THROTTLE_AXIS_FROM="Z"
      THROTTLE_AXIS_CODE=5
      THROTTLE_AXIS="Z"
      THROTTLE_MIN=0
      THROTTLE_MAX=65535

      BRAKE_AXIS_FROM="Y"
      BRAKE_AXIS_CODE=3
      BRAKE_AXIS="Y"
      BRAKE_MIN=0
      BRAKE_MAX=65535

      VIRTUAL_NAME="VRS DirectForce Pro Pedals"
      VIRTUAL_VENDOR="${vrsPedalsVendor}"
      VIRTUAL_PRODUCT="${vrsPedalsProduct}"

      # calibrating existing device
      ${pkgs.linuxConsoleTools}/bin/evdev-joystick --evdev "$DEVICE" --axis "$THROTTLE_AXIS_CODE" --minimum "$THROTTLE_MIN" --maximum "$THROTTLE_MAX" --fuzz 0
      ${pkgs.linuxConsoleTools}/bin/evdev-joystick --evdev "$DEVICE" --axis "$BRAKE_AXIS_CODE" --minimum "$BRAKE_MIN" --maximum "$BRAKE_MAX" --fuzz 0

      # setting up virtual device
      # technically protopedal mirrors the calibration information of the physical device if not specified
      # by passing --axes 6 protopedal ensures availability of at least axis X, Y, Z, RX, RY and RZ
      # and similar for --buttons
      ${getExe protopedal} \
        --name "$VIRTUAL_NAME" --vendor $VIRTUAL_VENDOR --product $VIRTUAL_PRODUCT --axes 6 --buttons 1 \
        --axis $THROTTLE_AXIS --min $THROTTLE_MIN --max $THROTTLE_MAX --source $THROTTLE_AXIS_FROM --invert \
        --axis $BRAKE_AXIS --min $BRAKE_MIN --max $BRAKE_MAX --source $BRAKE_AXIS_FROM --invert \
        "$DEVICE"
    '';
  };

  decrementHex = hexValue: toHexString ((fromHexString hexValue) - 1);

in

{
  options = {
    custom.roles.gaming.simracing = {
      enable = mkEnableOption "Simracing";
    };
  };

  config = mkIf cfg.enable {
    boot = {
      extraModulePackages = [ fanatecff ];
      kernelModules = [ "hid-fanatec" ];
    };

    environment.systemPackages = [
      vrsPedalsSetup
    ];

    services.udev = {
      packages = [ fanatecff ];
      extraRules = ''
        SUBSYSTEM=="input", KERNEL=="event*", ATTRS{idVendor}=="${vrsPedalsVendor}", ATTRS{idProduct}=="${decrementHex vrsPedalsProduct}", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_WANTS}+="${vrsPedalsSetupScript}@$devnode.service"
      '';
    };

    systemd.services."${vrsPedalsSetupScript}@" = {
      description = "Enable and configure VRS DirectForce Pro pedals";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${getExe vrsPedalsSetup} %I";
      };
    };
  };
}
