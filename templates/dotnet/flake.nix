{
  description = "DotNet development flake";

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
        dotnet = pkgs.dotnet-sdk;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            dotnet
          ];

          DOTNET_CLI_TELEMETRY_OPTOUT = 1;
          DOTNET_NOLOGO = 1;
          DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = 1;
        };

      }
    );
}
