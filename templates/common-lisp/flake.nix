{
  description = "Common Lisp dev shell (SBCL + lem-language-server)";

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

        # lem-language-server isn't packaged in nixpkgs. It's installed once,
        # globally, via roswell/qlot (cached under ~/.roswell, same as the
        # `ros` toolchain itself) with a one-time setup:
        #
        #   ros install qlot
        #   lem-language-server --help
        #   git clone https://github.com/lem-project/micros.git \
        #     ~/.roswell/lisp/quicklisp/local-projects/micros
        #
        # The second step clones lem-project/lem and builds the server via
        # qlot (needs openssl/ncurses below). The third step is required
        # separately: at runtime the server shells out to a plain `ros run -s
        # micros ...` for its eval backend, which is a fresh process outside
        # qlot's project-local dependency pin, so `micros` (a lem-project-only
        # dependency, not in the default Quicklisp dist) must also be
        # reachable from Quicklisp's own local-projects dir.
        #
        # The wrapper below works around a separate issue: the .ros launcher
        # can't find its own `lem` / `lem-language-server` ASDF systems when
        # run standalone, because `lem-project/lem` clones two levels deep
        # under ~/.roswell/local-projects and plain ASDF only scans one level.
        # It forces a recursive source-registry over that directory first.
        lem-language-server = pkgs.writeShellScriptBin "lem-language-server" ''
          exec ${pkgs.roswell}/bin/ros \
            -e '(ros:quicklisp)' \
            -e '(asdf:initialize-source-registry (list (quote :source-registry) (list :tree (truename "'"$HOME"'/.roswell/local-projects/")) :inherit-configuration))' \
            "$HOME/.roswell/local-projects/lem-project/lem/roswell/lem-language-server.ros" \
            "$@"
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.sbcl
            pkgs.rlwrap # readline history/editing for the raw `sbcl` REPL
            pkgs.roswell # Lisp implementation/version manager; also bootstraps Quicklisp
            lem-language-server
            pkgs.openssl # cl+ssl (pulled in by qlot) loads libcrypto/libssl via CFFI
            pkgs.ncurses.dev # header+lib needed to build cl-charms, a lem dependency
          ];

          # Quicklisp libraries that load native libs via CFFI (cl+ssl, cl-charms)
          # look on the standard FHS path, which doesn't exist on NixOS. Put
          # nixpkgs' openssl/ncurses on the dynamic linker path so
          # `cffi:load-foreign-library` finds them, and ncurses' headers on the
          # C include path for the one-time setup build above.
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.openssl
            pkgs.ncurses
          ];
          C_INCLUDE_PATH = "${pkgs.ncurses.dev}/include";

          shellHook = ''
            alias sbcl="rlwrap sbcl"
            export PATH="$HOME/.roswell/bin:$PATH"
          '';
        };
      }
    );
}
