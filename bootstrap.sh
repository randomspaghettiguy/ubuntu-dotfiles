#!/usr/bin/env bash
# First-time setup on a NixOS-WSL machine.
# Run once. After it finishes, use ./rebuild.sh for every later change.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REAL_USER="$(whoami)"
HOST="$(hostname)"

echo "==> Step 1: sanity checks"
if [ ! -e /etc/NIXOS ]; then
  echo "    This machine does not look like NixOS. Wrong bootstrap script."
  exit 1
fi
echo "    NixOS detected, host = $HOST, user = $REAL_USER"

if grep -q REPLACE_ME "$DIR/configuration.nix"; then
  echo
  echo "    STOP: configuration.nix still has system.stateVersion = \"REPLACE_ME\"."
  echo "    Copy the real value from your existing install:"
  echo
  grep stateVersion /etc/nixos/configuration.nix 2>/dev/null || true
  echo
  exit 1
fi

echo "==> Step 2: check flake.nix matches this machine"
FLAKE_USER="$(sed -nE 's/^[[:space:]]*user = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n1)"
FLAKE_HOST="$(sed -nE 's/^[[:space:]]*host = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n1)"
if [ "$FLAKE_USER" != "$REAL_USER" ] || [ "$FLAKE_HOST" != "$HOST" ]; then
  echo "    flake.nix says user=\"$FLAKE_USER\" host=\"$FLAKE_HOST\""
  echo "    this machine is  user=\"$REAL_USER\" host=\"$HOST\""
  read -r -p "    Rewrite flake.nix to match? [y/N] " REPLY
  if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    sed -i -E "s/^([[:space:]]*user = \")[^\"]+(\";.*)/\1${REAL_USER}\2/" "$DIR/flake.nix"
    sed -i -E "s/^([[:space:]]*host = \")[^\"]+(\";.*)/\1${HOST}\2/" "$DIR/flake.nix"
    echo "    Updated. Review with: git diff flake.nix"
  else
    echo "    Edit the user/host lines in flake.nix yourself, then re-run."
    exit 1
  fi
else
  echo "    flake.nix already matches, nothing to do."
fi

echo "==> Step 3: symlink this repo to ~/.dotfiles"
# home.nix resolves its mkOutOfStoreSymlink paths through ~/.dotfiles.
ln -sfn "$DIR" "$HOME/.dotfiles"

echo "==> Step 4: stage files for git"
# Nix reads flakes in a git repo THROUGH git - untracked files are invisible.
if [ -d "$DIR/.git" ]; then
  git -C "$DIR" add -A
  echo "    staged (not committed)"
fi

echo "==> Step 5: first rebuild"
# Flakes aren't enabled yet on a stock NixOS-WSL install, hence the explicit
# flag. configuration.nix turns them on permanently, so rebuild.sh won't need it.
sudo nixos-rebuild switch \
  --option extra-experimental-features 'nix-command flakes' \
  --flake "$HOME/.dotfiles#$HOST"

echo
echo "==> Done. Open a new shell, then use ./rebuild.sh for future changes."
