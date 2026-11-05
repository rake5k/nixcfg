# A `portableRc` entry: puts a TUI on PATH and defines a function that runs it
# with `$tmp` as its cwd file, then cds to the dir it wrote there on exit.
{
  name,
  package,
  run,
}:

''
  PATH="${package}/bin:$PATH"
  function ${name}() {
    local tmp="$(mktemp -t "${name}-cwd.XXXXX")"
    ${run}
    if cwd="$(<"$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }
''
