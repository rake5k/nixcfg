{
  custom.roles.backup.rsync.jobs.backup.excludes = [
    "/persist/var/lib/clamav/"
    "/var/lib/clamav/"
  ];

  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
  };
}
