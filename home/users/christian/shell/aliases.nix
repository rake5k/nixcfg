{ stdenv, lib }:

{
  # Enable aliases with `sudo`
  sudo = "sudo ";

  # System utilities
  df = "df -Tha --total";
  duh = "du -ach | sort -h";
  free = "free -mt";
  ps = "ps auxf";
  psg = "ps aux | grep -v grep | grep -i -e VSZ -e";

  # Safety nets
  cp = "cp -i";
  mv = "mv -i";
  rm = "rm -I --preserve-root=all --one-file-system";

  # Navigating
  "cd.." = "cd ..";
  d = "dirs -v | head -10";
  l = "eza -ghl --git --icons";
  la = "eza -aghl --git --icons";
  lal = "la | less";
  ll = "l";
  ls = "ls -h --color='auto'";
  lsa = "ls -a";
  lsl = "ls | less";
  tree = "eza --icons --tree";

  # File reading
  cat = "bat";
  grep = "rg";

  # File manager
  rr = "ranger";

  # Calendar shortcuts
  cal = "khal -v ERROR calendar 2>/dev/null";
  yesterday = "cal yesterday 24h --format '{start-end-time-style} {title}'";
  today = "cal today 24h --format '{start-end-time-style} {title}'";
  tomorrow = "cal tomorrow 24h --format '{start-end-time-style} {title}'";

  # Java REPL
  jshell = "nix shell nixpkgs#openjdk --command jshell";
  visualvm = "visualvm --cp:a ~/jmx/jmxremote_optional.jar";

  # PDF viewer
  mupdf = "mupdf-x11";

  # Password manager
  pass = "source pass";

  # Web
  wget = "wget -c";
  myip = "curl http://ipecho.net/plain; echo";
} // lib.optionalAttrs (!stdenv.isDarwin) {
  # Safety nets
  chgrp = "chgrp --preserve-root";
  chmod = "chmod --preserve-root";
  chown = "chown --preserve-root";
}
