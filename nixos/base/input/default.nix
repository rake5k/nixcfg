{
  services = {
    xserver.xkb = {
      layout = "ch,de,de";
      variant = ",bone,neo_qwertz";
      options = "grp:rctrl_toggle,grp_led:scroll";
    };
  };

  console.useXkbConfig = true;
}
