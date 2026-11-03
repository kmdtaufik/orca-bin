{ runCommand
, desktop-file-utils
, orca
}:

runCommand "orca-smoke-check" {
  nativeBuildInputs = [ desktop-file-utils ];
} ''
  test -x ${orca}/bin/orca-ide
  test -x ${orca}/bin/orca-ide-desktop
  test -f ${orca}/share/applications/orca-ide.desktop

  desktop-file-validate ${orca}/share/applications/orca-ide.desktop

  ${orca}/bin/orca-ide --help > help.txt
  grep -q "Usage: orca <command>" help.txt

  touch $out
''
