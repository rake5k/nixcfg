{ config, lib, pkgs, ... }:

with lib;

let

  username = "gamer";

in

{
  users.users."${username}" = {
    name = username;
    isNormalUser = true;
    uid = 1001;
    password = "";
  };
}
