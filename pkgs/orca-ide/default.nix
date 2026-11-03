{ lib
, stdenv
, fetchurl
, appimageTools
, makeWrapper
, git
, openssh
, ripgrep
, extraPackages ? [ ]
, addDefaultDeps ? false
}:

let
  sources = builtins.fromJSON (builtins.readFile ./versions.json);
  pname = "orca-ide";
  version = sources.version;

  system = stdenv.hostPlatform.system;

  selectArtifact = {
    "x86_64-linux" = {
      filename = "orca-linux.AppImage";
      hash = sources."x86_64-linux";
    };
    "aarch64-linux" = {
      filename = "orca-linux-arm64.AppImage";
      hash = sources."aarch64-linux";
    };
  };

  artifact = selectArtifact.${system} or (throw "Unsupported system: ${system}");

  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/${artifact.filename}";
    hash = artifact.hash;
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };

  defaultDeps = lib.optionals addDefaultDeps [ git openssh ripgrep ];
  allExtraPkgs = defaultDeps ++ extraPackages;
in
appimageTools.wrapType2 {
  inherit pname version src;

  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/orca-ide.desktop $out/share/applications/orca-ide.desktop
    install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/512x512/apps/orca-ide.png \
      $out/share/icons/hicolor/512x512/apps/orca-ide.png

    ${lib.optionalString (allExtraPkgs != [ ]) ''
      wrapProgram $out/bin/${pname} \
        --suffix PATH : ${lib.makeBinPath allExtraPkgs}
    ''}

    ln -s ${pname} $out/bin/${pname}-desktop

    substituteInPlace $out/share/applications/orca-ide.desktop \
      --replace-fail 'Exec=AppRun' "Exec=$out/bin/${pname}-desktop"
  '';

  meta = with lib; {
    description = "Next-gen IDE for parallel agentic development (multi-agent coding orchestrator)";
    homepage = "https://onorca.dev";
    license = licenses.mit;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "orca-ide";
  };
}
