# Samba

## Folder Structure

* `home`: Personal folder for authenticated users.
* `private`: Share for authenticated users.
* `public`: Share for authenticated and anonym users in the LAN/VPN.

More shares for simplified media management:

* `plex`: Plex media data.
* `photo`: Photo library data.

Recycle bin with 1 - 2 months retention with automated cleanup.

## User Set-up

* Configure user by NixOS configuration `users.users.<username>`.
* "Activate" Samba user:

  ```shell
  [admin@hyperion:~]$ sudo smbpasswd -a <username>
  New SMB password:
  Retype new SMB password:
  Added user <username>.
  ```

* Permit user to shared folder:

  ```shell
  # by group:
  [admin@hyperion:~]$ sudo setfacl -m g:users:rwx -R /data/share/<share>

  # or by user:
  [admin@hyperion:~]$ sudo setfacl -m u:<username>:rwx -R /data/share/<share>
  ```
