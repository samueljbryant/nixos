{
  description = "C development environment";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            clang-tools
            cmake
            gcc
            gdb
            pkg-config
            raylib
          ];
          env = {
            CMAKE_EXPORT_COMPILE_COMMANDS = "1";
          };
        };
      }
    );
}
