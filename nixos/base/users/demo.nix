_:

let

  username = "demo";

in

{
  users.users."${username}" = {
    name = username;
    isNormalUser = true;
    uid = 1001;
    initialPassword = "changeme";
  };
}
