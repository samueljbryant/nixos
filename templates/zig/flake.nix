{
  description = "Zig dev shell (zig-overlay)";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      zig-overlay,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ zig-overlay.overlays.default ];
        };

        zig = pkgs.zigpkgs.default;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            zig
            pkgs.zls
          ];
        };
      }

    );
}
