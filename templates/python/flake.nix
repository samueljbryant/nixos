{
  description = "Python dev shell (nixpkgs python + uv)";

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

        # Pin the interpreter declaratively. Change to python311/python312/etc.
        # per project — this is the reproducible part.
        # debugpy is bundled so nvim-dap-python's $PATH fallback (no project
        # .venv) can still debug; projects with a uv-managed .venv should add
        # their own `uv add --dev debugpy` to debug from inside the venv.
        python = pkgs.python314.withPackages (ps: [ ps.debugpy ]);

        # Native libraries that binary wheels (numpy, pydantic-core, greenlet,
        # playwright, ...) dlopen at runtime. A nixpkgs Python can't lean on
        # nix-ld for these the way a foreign interpreter does, so we put them on
        # LD_LIBRARY_PATH inside the shell. Add more here as projects need them.
        libs = with pkgs; [
          stdenv.cc.cc.lib # libstdc++.so.6 / libgcc
          zlib
          openssl
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            python
            pkgs.uv
          ];

          env = {
            # Make uv use THIS interpreter instead of downloading its own.
            UV_PYTHON = "${python}/bin/python";
            UV_PYTHON_PREFERENCE = "only-system";
            UV_PYTHON_DOWNLOADS = "never";

            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath libs;
          };
        };
      }
    );
}
