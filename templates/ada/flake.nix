{
  description = "Ada dev shell (gnat + gprbuild + alire)";

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
            pkgs.gnat14
            pkgs.gnat14Packages.gprbuild
            pkgs.alire
            pkgs.gnat14Packages.gnatprove
            pkgs.gmp
            pkgs.pkg-config
          ];

          # ada_language_server and gnatformat aren't in nixpkgs; install once via
          # alire (`alr install ada_language_server gnatformat`) and they'll be
          # picked up from ~/.alire/bin on PATH.
          shellHook = ''
            export PATH="$HOME/.alire/bin:$PATH"
          '';
        };
      }
    );
}
