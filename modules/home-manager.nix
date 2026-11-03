self:
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.orca-ide;
in
{
  options.programs.orca-ide = {
    enable = lib.mkEnableOption "Orca IDE";
    package = lib.mkPackageOption self.packages.${pkgs.stdenv.hostPlatform.system} "orca-ide" { };
    addDefaultDeps = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Append fallback git, openssh, and ripgrep to PATH via --suffix so user-installed tools win.";
    };
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional packages to append to Orca IDE's PATH via --suffix.";
      example = lib.literalExpression "[ pkgs.git pkgs.ripgrep pkgs.nodejs ]";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (cfg.package.override {
        inherit (cfg) addDefaultDeps extraPackages;
      })
    ];
  };
}
