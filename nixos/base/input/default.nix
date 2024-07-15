{
  services = {
    xserver.xkb = {
      layout = "de,de";
      variant = "neo_qwertz,bone";
      options = "grp:rctrl_toggle,grp_led:scroll";
    };
  };

  console.useXkbConfig = true;
}
