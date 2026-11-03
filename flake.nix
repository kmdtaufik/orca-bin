{
  description = "Orca IDE on NixOS - Next-gen IDE for parallel agentic development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
        orca = pkgs.callPackage ./pkgs/orca-ide { };
      in
      {
        packages.default = orca;
        packages.orca-ide = orca;

        apps.default = {
          type = "app";
          program = "${orca}/bin/orca-ide-desktop";
          meta.description = "Launch Orca IDE desktop application";
        };

        apps.cli = {
          type = "app";
          program = "${orca}/bin/orca-ide";
          meta.description = "Run Orca IDE CLI";
        };

        apps.update = {
          type = "app";
          program = toString (pkgs.writeShellScript "orca-update" ''
            export PATH="${pkgs.lib.makeBinPath [ pkgs.bash pkgs.curl pkgs.gnugrep pkgs.gnused pkgs.nix pkgs.coreutils ]}:$PATH"
            exec "${./scripts/update.sh}" "$@"
          '');
          meta.description = "Update Orca IDE upstream version and prefetch hashes";
        };

        checks.smoke = pkgs.callPackage ./checks/smoke.nix { inherit orca; };
      }
    ) // {
      overlays = rec {
        default = orca-ide;
        orca-ide = final: prev: {
          orca-ide = self.packages.${prev.stdenv.hostPlatform.system}.orca-ide;
        };
      };

      nixosModules = rec {
        default = orca-ide;
        orca-ide = import ./modules/nixos.nix self;
      };

      homeManagerModules = rec {
        default = orca-ide;
        orca-ide = import ./modules/home-manager.nix self;
      };

      homeModules = self.homeManagerModules;
    };
}
