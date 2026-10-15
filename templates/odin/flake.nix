{
  description = "Odin dev shell (nixpkgs odin + ols + lldb)";

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

      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.odin
            pkgs.ols
            pkgs.lldb # provides lldb-dap, used by nvim-dap (see config/nvim/lua/plugins/dap.lua)
          ];
          # Nix glibc treats the _FORTIFY_SOURCE warning as an error when cgo
          # compiles without -0; needed for `dlv debug` and any cgo build.
          CGO_CFLAGS = "-O2";
        };
      }
    );
}
