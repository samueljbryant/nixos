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
            pkgs.gnat15
            pkgs.gnat15Packages.gprbuild
            pkgs.alire
            pkgs.gnat15Packages.gnatprove
            pkgs.gmp
            pkgs.pkg-config
            pkgs.unzip
          ];

          # ada_language_server and gnatformat aren't in nixpkgs; install once via
          # alire (`alr install ada_language_server gnatformat`) and they'll be
          # picked up from ~/.alire/bin on PATH.
          #
          # alr downloads its own prebuilt GNAT toolchain rather than using the
          # nixpkgs one above; that toolchain's `ld` is a generic-Linux binary
          # that expects glibc's crt objects (Scrt1.o, crti.o, crtn.o) and
          # libc/libdl at standard FHS paths, which don't exist on NixOS.
          # Pointing LIBRARY_PATH at nixpkgs' glibc lets it find them.
          shellHook = ''
            export PATH="$HOME/.alire/bin:$PATH"
            export LIBRARY_PATH="${pkgs.glibc}/lib''${LIBRARY_PATH:+:$LIBRARY_PATH}"
            export CPATH="${pkgs.glibc.dev}/include''${CPATH:+:$CPATH}"
          '';
        };
      }
    );
}
