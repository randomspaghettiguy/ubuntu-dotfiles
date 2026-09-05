 {
  description = "dotfiles - NixOS-WSL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # The structural replacement for nix-darwin. Same job: owns the system
    # layer. nix-darwin does macOS defaults + Homebrew; this does WSL integration.
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ self, nixpkgs, nixos-wsl, home-manager, ... }:
    let
      # ─── The two lines to change ───────────────────────────────────────
      user = "thinh";
      host = "nixos"; # must match `hostname`; it's the flake target you rebuild
      # ───────────────────────────────────────────────────────────────────
    in
    {
      # Compare to the video's `darwinConfigurations."mac"` - same shape.
      # Rebuild with: sudo nixos-rebuild switch --flake ~/.dotfiles#nixos
      nixosConfigurations.${host} = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit user host; };
        modules = [
          nixos-wsl.nixosModules.default # <- was nix-darwin
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Renames pre-existing files instead of aborting the switch.
            home-manager.backupFileExtension = "hm-backup";
            home-manager.extraSpecialArgs = { inherit user; };
            home-manager.users.${user} = import ./home.nix;
          }
        ];
      };
    };
}
