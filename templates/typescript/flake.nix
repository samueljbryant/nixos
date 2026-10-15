{
  description = "Typescript dev shell (nixpkgs node)";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
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
        node = pkgs.nodejs_latest;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            node
            pkgs.typescript-language-server
            pkgs.eslint
            pkgs.vscode-css-languageserver
          ];
        };
      }

    );
}
