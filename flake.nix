{
  description = "dotfiles - Ubuntu port (standalone home-manager, no nix-darwin)";

  inputs = {
    # nixos-26.05 is the Linux twin of the upstream repo's nixpkgs-26.05-darwin.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # No nix-darwin and no nix-homebrew here. Ubuntu already owns the system
    # layer (apt, systemd, GNOME settings); home-manager owns your home dir.
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # ─── The two lines to change if this isn't your machine ───────────────
      user = "thinh"; # your Ubuntu username (`whoami`); bootstrap.sh offers to fix this
      system = "x86_64-linux"; # use "aarch64-linux" on ARM (Raspberry Pi, Ampere, etc.)
      # ─────────────────────────────────────────────────────────────────────

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # claude-code is unfree
      };
    in
    {
      # The Linux equivalent of `darwinConfigurations."mac"`.
      # Built with: home-manager switch --flake ~/.dotfiles#<user>
      homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit user; };
        modules = [ ./home.nix ];
      };
    };
}
