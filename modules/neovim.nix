{ pkgs, ... }:

{
  # Install Neovim and dependencies
  home.packages = with pkgs; [
    # Tools required for Telescope
    neovim
    fd
    fzf

    # Language Servers
    lua-language-server
    nil # nix language server
    nixpkgs-fmt # nix formatter
    basedpyright
    ruff
    zls

    # Needed for lazy.nvim
    nodejs

    # Needed for nvim-treesitter parser installs
    tree-sitter
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };
  home.sessionPath = [ "$HOME/.dotnet/tools" ];

}
