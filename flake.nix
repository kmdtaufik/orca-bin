{
  description = "Orca IDE on NixOS - Next-gen IDE for parallel agentic development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        orca = pkgs.callPackage ./default.nix { };
      in
      {
        packages.default = orca;
        packages.orca-ide = orca;

        apps.default = flake-utils.lib.mkApp {
          drv = orca;
          name = "orca-ide";
        };

        apps.update = {
          type = "app";
          program = toString (pkgs.writeShellScript "orca-update" ''
            export PATH="${pkgs.lib.makeBinPath [ pkgs.bash pkgs.curl pkgs.gnugrep pkgs.gnused pkgs.nix pkgs.coreutils ]}:$PATH"
            exec "${./update.sh}" "$@"
          '');
        };
      }
    );
}
