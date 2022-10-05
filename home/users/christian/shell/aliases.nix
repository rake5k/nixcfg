{
  # Enable aliases with `sudo`
  sudo = "sudo ";

  # Navigating
  d = "dirs -v | head -10";
  l = "exa -hl --git --icons";
  la = "exa -ahl --git --icons";
  ll = "l";
  ls = "ls -sh --color='auto'";
  lsa = "ls -a";
  tree = "l --tree";

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

  # Open Fontawesome icon selector
  fa = "fontawesome-menu -f icon-list.txt";

  # Java REPL
  jshell = "nix-shell -p openjdk --command jshell";
  visualvm = "visualvm --cp:a ~/jmx/jmxremote_optional.jar";

  # PDF viewer
  mupdf = "mupdf-x11";

  # Password manager
  pass = "source pass";
}
