#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles
# No sudo: standalone home-manager only ever writes inside your home directory.
exec home-manager switch -b backup --flake ~/.dotfiles#"$(whoami)"
