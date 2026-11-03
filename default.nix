{ lib, fetchurl, appimageTools }:

let
  sources = builtins.fromJSON (builtins.readFile ./versions.json);
  pname = "orca-ide";
  version = sources.version;

  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    hash = sources.hash;
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/orca-ide.desktop $out/share/applications/orca-ide.desktop
    install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/512x512/apps/orca-ide.png \
      $out/share/icons/hicolor/512x512/apps/orca-ide.png
    substituteInPlace $out/share/applications/orca-ide.desktop \
      --replace-fail 'Exec=AppRun' "Exec=$out/bin/${pname}"
  '';

  meta = with lib; {
    description = "Next-gen IDE for parallel agentic development (multi-agent coding orchestrator)";
    homepage = "https://onorca.dev";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "orca-ide";
  };
}
