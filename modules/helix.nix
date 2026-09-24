{ pkgs, ... }:

{
  # Install Helix and dependencies
  home.packages = with pkgs; [
    helix
  ];
}
