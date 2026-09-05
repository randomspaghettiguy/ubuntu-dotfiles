#!/usr/bin/env bash
# Re-applies the config. Run this after every change.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" "$HOME/.dotfiles"

HOST="$(hostname)"

# --flake takes an absolute path deliberately: `sudo` would expand ~ to root's
# home, not yours.
exec sudo nixos-rebuild switch --flake "$HOME/.dotfiles#$HOST"
