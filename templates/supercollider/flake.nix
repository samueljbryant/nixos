{
  description = "SuperCollider project shell — puts the in-development sc_lsp on PATH for nvim";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          # The language server is still unstable, so we deliberately DON'T package
          # it with Nix. Instead we point PATH at the binary you build imperatively
          # with cargo in its own repo (bootstrapped via `initrs`). Rebuild there
          # with `cargo build --release` and the new binary is picked up on the next
          # shell entry — no nixos-rebuild. Swap `release` -> `debug` below if you
          # want to attach faster iterative builds.
          #
          # nvim resolves `sc_lsp` from PATH (see config/nvim/.../lspconfig.lua), so
          # the server only attaches in directories where this shell is active.
          shellHook = ''
            export PATH="$HOME/Development/work/projects/sc_lsp/target/release:$PATH"
          '';
        };
      });
}
