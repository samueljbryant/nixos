{
  description = "Zig dev shell (zig-overlay)";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    zls.url = "github:zigtools/zls";
    zls.inputs.nixpkgs.follows = "nixpkgs";
    zls.inputs.zig-overlay.follows = "zig-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      zig-overlay,
      flake-utils,
      zls,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ zig-overlay.overlays.default ];
        };

        # zig = pkgs.zigpkgs.default;
        zig = pkgs.zigpkgs.master;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            zig
            zls
          ];
        };
      }
    );
}
