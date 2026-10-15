{
  description = "C/C++ dev shell (clang-tools, lldb)";

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
            pkgs.clang-tools
            pkgs.lldb # provides lldb-dap, used by nvim-dap (see config/nvim/lua/plugins/dap.lua)
          ];
          CGO_CFLAGS = "-O2";
        };
      }
    );
}
