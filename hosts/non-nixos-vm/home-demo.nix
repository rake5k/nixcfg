{
  custom = {
    base.non-nixos.enable = true;

    users = {
      demo.enable = true;
    };

    roles = {
      desktop.enable = true;
      web.enable = true;
    };
  };
}
