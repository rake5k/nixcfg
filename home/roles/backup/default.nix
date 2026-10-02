{ lib, ... }:

{
  # Collected by the NixOS rsync backup role into every job; inert without it.
  options.custom.roles.backup.excludes = lib.mkOption {
    type = with lib.types; listOf str;
    default = [ ];
    description = "Paths of this user to exclude from the system rsync backup";
    example = [ "/home/alice/scratch/" ];
  };
}
