{
  bb = "blame -C -C -C";
  co = "checkout";
  cp = "cherry-pick";
  changes = "diff --name-status -r";
  d = "diff";
  dh = "diff HEAD";
  ds = "diff --staged";
  dw = "diff --color-words";
  fu = "commit -a --fixup=HEAD";
  ignored = "ls-files --exclude-standard --ignored --others";
  lg = "log --graph --full-history --all --color --pretty=format:'%x1b[33m%h%x09%C(blue)(%ar)%C(reset)%x09%x1b[32m%d%x1b[0m%x20%s%x20%C(dim white)-%x20%G?%x20%an%C(reset)'";
  lgrep = "log -p -S";
  rc = "rebase --continue";
  ri = "rebase --interactive --autosquash";
  rs = "rebase --skip";
  s = "status";
  ss = "status -s";
  staash = "stash --all";
}
