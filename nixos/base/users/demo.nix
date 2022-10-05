{ config, lib, pkgs, ... }:

with lib;

let

  username = "demo";

in

{
  users.users."${username}" = {
    name = username;
    isNormalUser = true;
    uid = 1000;
    initialPassword = "changeme";
  };
}
