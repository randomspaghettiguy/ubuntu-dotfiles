{ config, pkgs, lib, user, host, ... }:

# The system layer. This is the direct counterpart of the video's
# configuration.nix - it just describes WSL instead of macOS.

{
  # ─── WSL integration (replaces nix-darwin's macOS defaults) ──────────────
  wsl.enable = true;
  wsl.defaultUser = user; # this is why you had to `su - thinh`; now you land as thinh
  wsl.startMenuLaunchers = true; # Linux GUI apps appear in the Windows Start menu
  # wsl.useWindowsDriver = true;  # uncomment if you want GPU/OpenGL from the host

  networking.hostName = host;

  # ─── Nix itself ──────────────────────────────────────────────────────────
  # This is what was missing: stock NixOS ships with flakes off, which is why
  # bootstrap.sh died with "experimental Nix feature 'nix-command' is disabled".
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nixpkgs.config.allowUnfree = true; # claude-code is unfree

  # ─── Locale ──────────────────────────────────────────────────────────────
  time.timeZone = "Asia/Ho_Chi_Minh";
  i18n.defaultLocale = "en_US.UTF-8";

  # System-wide packages. Keep this list short - almost everything belongs in
  # home.nix instead. git lives here so a broken home config is still fixable.
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  users.users.${user} = {
    isNormalUser = true;
    uid = 1002;              # must match the existing /etc/passwd entry
    extraGroups = [ "wheel" ];
  };

  # ─── IMPORTANT ───────────────────────────────────────────────────────────
  # Do NOT invent this value. Copy it verbatim from your existing
  # /etc/nixos/configuration.nix - it records which NixOS release this machine
  # was FIRST installed with, and changing it can break stateful data.
  #   grep stateVersion /etc/nixos/configuration.nix
  system.stateVersion = "26.05"; # e.g. "25.11"
}
