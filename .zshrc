export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

source $ZSH/oh-my-zsh.sh

# ---- Shared aliases and functions (zsh/aliases.zsh, also used by nixos-config) ----
# Resolves the ~/.zshrc symlink back to this repo; falls back to ~/projects/my-shell.
MY_SHELL_DIR="${${(%):-%x}:A:h}"
[[ -r "$MY_SHELL_DIR/zsh/aliases.zsh" ]] || MY_SHELL_DIR="$HOME/projects/my-shell"
source "$MY_SHELL_DIR/zsh/aliases.zsh"

# ---- Syntax highlighting: commands turn green when they exist, red when they don't ----
# Install: macOS `brew install zsh-syntax-highlighting`, Ubuntu `sudo apt install zsh-syntax-highlighting`.
# Must stay at the end of .zshrc.
for f in \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  if [[ -r "$f" ]]; then
    source "$f"
    # Don't underline paths
    ZSH_HIGHLIGHT_STYLES[path]=none
    ZSH_HIGHLIGHT_STYLES[path_prefix]=none
    break
  fi
done
unset f
