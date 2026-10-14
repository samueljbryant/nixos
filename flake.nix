{
  description = "NixOs from Scratch";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Unofficial Wispr Flow Linux port. Not following our nixpkgs: its
    # derivation needs electron_42, which may not exist yet on the
    # nixos-26.05 branch we pin above, and the upstream flake already locks
    # a known-good nixpkgs-unstable for it.
    wispr-flow-linux.url = "github:wispr-flow-linux/wispr-flow-linux";
    # noctalia = {
    #   url = "github:noctalia-dev/noctalia-shell";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    fsel.url = "github:Mjoyufull/fsel";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    {
      nixosConfigurations.nixos-laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              extraSpecialArgs = { inherit inputs; };
              useUserPackages = true;
              users.sam = import ./home.nix;
              backupFileExtension = "backup";
            };
          }
        ];
      };
    };
}
