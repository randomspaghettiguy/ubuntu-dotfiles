#!/usr/bin/env bash
# Takes a fresh Ubuntu box from nothing to a built home-manager config.
# Run this once. After it finishes, use ./rebuild.sh for every later change.
#
# Differences from the macOS bootstrap.sh:
#   - no sudo (standalone home-manager only writes inside your home dir)
#   - GNU sed syntax (`sed -i -E`, not BSD's `sed -i '' -E`)
#   - `-b backup` on the first switch, because Ubuntu ships a ~/.bashrc
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

echo "==> Step 1: Determinate Nix"
if command -v nix >/dev/null 2>&1; then
  echo "    nix already installed, skipping"
else
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
fi
# The installer only patches *new* shells' PATH, so pull nix into this one.
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

echo "==> Step 2: symlink this repo to ~/.dotfiles"
# home.nix resolves its mkOutOfStoreSymlink paths through ~/.dotfiles, so this
# has to exist before the first switch or the build will fail to find them.
ln -sfn "$DIR" ~/.dotfiles

echo "==> Step 3: personalize the configured username"
REAL_USER="$(whoami)"
FLAKE_USER="$(sed -nE 's/^[[:space:]]*user = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n1)"
if [ -z "$FLAKE_USER" ]; then
  echo "    Could not find the single \"user = \" line in flake.nix."
  echo "    Edit flake.nix yourself before continuing."
  exit 1
elif [ "$FLAKE_USER" != "$REAL_USER" ]; then
  echo "    flake.nix is configured for user \"$FLAKE_USER\", but you are \"$REAL_USER\"."
  read -r -p "    Rewrite flake.nix's \"user = \" line to \"$REAL_USER\"? [y/N] " REPLY
  if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    sed -i -E "s/^([[:space:]]*user = \")[^\"]+(\";.*)/\1${REAL_USER}\2/" "$DIR/flake.nix"
    echo "    Updated. Review the change with: git diff flake.nix"
  else
    echo "    Skipped. Edit the single \"user = \" line in flake.nix yourself before continuing."
    exit 1
  fi
else
  echo "    flake.nix already matches \"$REAL_USER\", nothing to do."
fi

echo "==> Step 4: first home-manager switch"
# home-manager doesn't exist yet on a fresh machine, so run it straight from
# the flake this once. After this, `home-manager` is on your PATH.
#
# -b backup renames any file home-manager wants to own but didn't create --
# Ubuntu's stock ~/.bashrc and ~/.profile become ~/.bashrc.backup etc.
# Without it the first switch aborts with "would be clobbered".
nix run github:nix-community/home-manager/release-26.05 -- \
  switch -b backup --flake ~/.dotfiles#"$REAL_USER"

echo
echo "==> Done. Open a new terminal, then use ./rebuild.sh for future changes."
echo "    Your previous shell config is saved at ~/.bashrc.backup"
