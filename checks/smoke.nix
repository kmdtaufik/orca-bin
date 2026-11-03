{ runCommand
, desktop-file-utils
, orca
}:

runCommand "orca-smoke-check" {
  nativeBuildInputs = [ desktop-file-utils ];
} ''
  # Verify binaries exist and are executable
  test -x ${orca}/bin/orca-ide
  test -x ${orca}/bin/orca-ide-desktop
  test -f ${orca}/share/applications/orca-ide.desktop

  # Verify desktop file format specification validity
  desktop-file-validate ${orca}/share/applications/orca-ide.desktop

  # In environments where nested user namespaces are supported, verify CLI help.
  # Inside restricted sandbox builders (e.g. CI nixbld containers), bwrap cannot nest uid maps.
  if ${orca}/bin/orca-ide --help > help.txt 2>/dev/null; then
    grep -q "Usage: orca <command>" help.txt
  fi

  touch $out
''
