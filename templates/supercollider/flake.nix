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
        # The in-development sc_lsp is deliberately NOT packaged in Nix while it's
        # unstable. Its binary is put on PATH in .envrc (which handles the
        # debug/release profile toggle in plain bash — see that file). This shell
        # is just the direnv anchor + home for any real Nix tooling you add later
        # (sclang, formatters, and eventually a packaged sc_lsp).
        devShells.default = pkgs.mkShell {
          packages = [ ];
        };
      });
}
