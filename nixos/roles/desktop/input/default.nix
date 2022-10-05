{ config, lib, ... }:

with lib;

let

  baseCfg = config.custom.base;

in

{
  services = {
    xserver = {
      layout = "ch";

      # Touchpad settings
      libinput = {
        enable = true;
        touchpad = {
          naturalScrolling = true;
          disableWhileTyping = true;
          sendEventsMode = "disabled-on-external-mouse";
        };
      };
    };

    udev.extraRules = ''
      KERNEL=="event*", SUBSYSTEM=="input", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
      KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    '';
  };

  console.useXkbConfig = true;

  users.groups = {
    input.members = baseCfg.users;
    uinput.members = baseCfg.users;
  };
}
