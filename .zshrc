export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

source $ZSH/oh-my-zsh.sh

# ---- Custom aliases ----
unalias venv 2>/dev/null || true

function venv() {
  if [[ ! -f requirements.txt ]]; then
    echo "Error: requirements.txt not found in $(pwd)"
    return 1
  fi

  if typeset -f deactivate >/dev/null 2>&1; then
    deactivate
  fi

  if [[ -d .venv ]]; then
    rm -rf .venv || return 1
  fi

  uv venv .venv || return 1
  if [[ -f .venv/bin/activate ]]; then
    source .venv/bin/activate
  else
    echo "Error: .venv/bin/activate was not created"
    return 1
  fi

  uv pip install -r requirements.txt || return 1
}

# Alembic aliases
alias au='uv run alembic upgrade head'
alias ad='uv run alembic downgrade -1'
alias acu='uv run alembic current'
alias als='uv run alembic history'
alias areva='uv run alembic revision --autogenerate -m'

# Git aliases
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gba='git --no-pager branch --all'
alias gbD='git branch -D'
alias gcm='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gf='git fetch'
alias gfa='git fetch --all --prune'
alias gfo='git fetch origin'
alias gpu='git pull'

function gfp {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "Error: Not in a git repository"
    return 1
  }

  local force_cleanup=false
  if [[ "$1" == "--force" ]]; then
    force_cleanup=true
  elif [[ -n "$1" ]]; then
    echo "Usage: gfp [--force]"
    return 1
  fi

  local remote
  for remote in $(git remote); do
    git fetch "$remote" --prune || {
      echo "Warning: could not fetch remote '$remote' (skipping)"
      continue
    }
  done

  local current_branch
  current_branch=$(git branch --show-current 2>/dev/null)

  local remote_branches
  remote_branches=$(
    git for-each-ref --format='%(refname:strip=3)' refs/remotes \
      | awk '!/^HEAD$/ && !/^$/ { print }' \
      | sort -u
  )

  local stale_branches=()
  local branch
  while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue

    if [[ "$branch" == "main" || "$branch" == "master" ]]; then
      continue
    fi

    if [[ "$branch" == "$current_branch" ]]; then
      continue
    fi

    if ! echo "$remote_branches" | grep -qx "$branch"; then
      stale_branches+=("$branch")
    fi
  done < <(git for-each-ref --format='%(refname:strip=2)' refs/heads | sort -u)

  if [[ ${#stale_branches[@]} -eq 0 ]]; then
    echo "No stale local branches found"
    return 0
  fi

  echo "Stale local branches with no matching remote branch:"
  printf '%s\n' "${stale_branches[@]}"

  if [[ "$force_cleanup" == true ]]; then
    for branch in "${stale_branches[@]}"; do
      git branch -D "$branch" || return 1
    done
  else
    echo "Run 'gfp --force' to delete these local branches."
  fi
}

# Protected git push - prevents pushing to main/master
function gp {
  local current_branch=$(git branch --show-current 2>/dev/null)
  
  if [[ -z "$current_branch" ]]; then
    echo "Error: Not in a git repository"
    return 1
  fi
  
  if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
    echo "Error: Direct push to '$current_branch' branch is not allowed"
    echo "Please create a feature branch and push from there"
    return 1
  fi
  
  git push --set-upstream origin "$current_branch" "$@"
}

alias gmom='git merge origin/main'
alias gst='git status'
alias gsts='git status --short'

# Docker aliases
alias d='docker'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drmi='docker rmi'
alias drm='docker rm'
alias dlog='docker logs'
alias dlogf='docker logs -f'
alias dexec='docker exec -it'
alias dstop='docker stop'
alias dstart='docker start'
alias drestart='docker restart'

# Docker Compose aliases
alias dcu='docker-compose up'
alias dcud='docker-compose up -d'
alias dcub='docker-compose up --build'
alias dcd='docker-compose down'
alias dcdv='docker-compose down -v'
alias dcb='docker-compose build'
alias dcr='docker-compose restart'

unalias dcfr 2>/dev/null || true
unalias dcfrd 2>/dev/null || true

function dcfr {
  if [[ $# -gt 0 ]]; then
    docker-compose up --no-deps --build --force-recreate "$@"
  else
    docker-compose down -v
    docker-compose build
    docker-compose up
  fi
}

function dcfrd {
  if [[ $# -gt 0 ]]; then
    docker-compose up -d --no-deps --build --force-recreate "$@"
  else
    docker-compose down -v
    docker-compose build
    docker-compose up -d
  fi
}

# Create a GitHub PR from the current branch
function ghprc() {
  # require GitHub CLI
  command -v gh >/dev/null 2>&1 || { echo "Error: GitHub CLI 'gh' not found"; return 1; }

  local current_branch
  current_branch=$(git branch --show-current 2>/dev/null)

  if [[ -z "$current_branch" ]]; then
    echo "Error: Not in a git repository"
    return 1
  fi

  # prevent PR creation from main/master if you want (optional)
  if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
    echo "Error: Create PRs from a feature branch (current: $current_branch)"
    return 1
  fi

  # If branch isn't pushed yet, push it first (uses your gp function if present)
  if ! git ls-remote --exit-code --heads origin "$current_branch" >/dev/null 2>&1; then
    if typeset -f gp >/dev/null 2>&1; then
      gp || return 1
    else
      git push -u origin "$current_branch" || return 1
    fi
  fi

  # Pass all args through to gh. Your usage works:
  # ghprc -m "title"
  gh pr create "$@"
}

function grho() {
  local branch="$1"

  if [[ -z "$branch" ]]; then
    echo "Usage: grho <branch>"
    return 1
  fi

  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "Error: Not in a git repository"
    return 1
  }

  git fetch origin "$branch" >/dev/null 2>&1 || {
    echo "Error: Could not fetch origin/$branch (branch may not exist)"
    return 1
  }

  git reset --hard "origin/$branch"
}


. "$HOME/.local/bin/env"

alias python=python3

# Ruff via uv
alias uvrr='uv run ruff'

function gwc() {
  git worktree list | tail -n +2 | awk '{print $1}' | while read -r wt; do
    echo "Removing: $wt"
    git worktree remove --force "$wt"
  done
}
