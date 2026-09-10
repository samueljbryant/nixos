{
  description = "Dotnet dev shell (nixpkgs dotnet-sdk + roslyn-ls + csharpier + netcoredbg, for easy-dotnet.nvim)";

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
          packages = [
            pkgs.dotnet-sdk_10
            pkgs.roslyn-ls # official Roslyn LSP (the "C# Dev Kit" server), pointed at below
            pkgs.csharpier # formatter, picked up by easy-dotnet/conform
            pkgs.netcoredbg # debug adapter easy-dotnet drives for DAP
          ];

          env = {
            DOTNET_ROOT = "${pkgs.dotnet-sdk_10}";
            DOTNET_CLI_TELEMETRY_OPTOUT = "1";
            DOTNET_NOLOGO = "1";

            # Tells easy-dotnet-server's RoslynStartCommand to launch this dll
            # directly instead of shelling out to `dotnet tool install --global
            # roslyn-language-server` (see EasyDotnet.IDE/Services/RoslynLocator.cs
            # and RoslynStartCommand.cs in GustavEikaas/easy-dotnet-server).
            EASY_DOTNET_ROSLYN_DLL_PATH = "${pkgs.roslyn-ls}/lib/roslyn-ls/Microsoft.CodeAnalysis.LanguageServer.dll";
          };

          # EasyDotnet (the CLI companion easy-dotnet.nvim shells out to) isn't
          # packaged in Nix; install once with `dotnet tool install -g EasyDotnet`
          # and it lands in ~/.dotnet/tools, put on PATH here.
          shellHook = ''
            export PATH="$HOME/.dotnet/tools:$PATH"
          '';
        };
      }
    );
}
