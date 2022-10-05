{
  enable = true;
  controlMaster = "auto";
  controlPath = "~/.ssh/master-%r@%n:%p";
  controlPersist = "10m";
}
