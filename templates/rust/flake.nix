{
  description = "Rust dev shell (rust-overlay)";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        # Pin the toolchain declaratively. If you add a rust-toolchain.toml,
        # swap the line below for:
        #   rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
          # targets = [ "wasm32-unknown-unknown" ];  # cross targets, if needed
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            rustToolchain
            # Native build deps — add per project as crates require them:
            pkgs.pkg-config
            pkgs.openssl
          ];

          # So the `openssl-sys` crate links the Nix OpenSSL instead of vendoring.
          env.OPENSSL_NO_VENDOR = "1";
        };
      });
}
