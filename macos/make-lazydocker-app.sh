#!/usr/bin/env bash
# Builds ~/Applications/Lazydocker.app so Spotlight can launch lazydocker in
# its own Ghostty window. Re-run if lazydocker moves (e.g. Homebrew prefix change).
set -euo pipefail

bin="$(command -v lazydocker)" || { echo "lazydocker not found: brew install lazydocker" >&2; exit 1; }
app="$HOME/Applications/Lazydocker.app"

mkdir -p "$HOME/Applications"
rm -rf "$app"
# -n starts a separate Ghostty instance; quitting lazydocker closes it.
osacompile -o "$app" -e "do shell script \"open -na Ghostty --args --title=Lazydocker --quit-after-last-window-closed=true -e $bin\""

echo "Built $app. Search Spotlight for Lazydocker."
