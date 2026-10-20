# ms CLI

Multi-service workspace management tool.

## Installation

### Prerequisites

- **uv**: This tool uses `uv` for Python virtual environment management.
  ```bash
  # macOS/Linux
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ```
  See [uv documentation](https://docs.astral.sh/uv/#installation) for other installation methods.

### Install ms CLI

```bash
# From workspace root
pip install -e ./my-zsh
```

## Shell Integration (Zsh)

Add these lines to your `~/.zshrc`:

```bash
# Initialize zsh completion system (if not already done)
autoload -Uz compinit && compinit

# ms aliases and completion
eval "$(ms aliases)"
eval "$(ms completion)"
```

Then reload your shell:

```bash
source ~/.zshrc
```

**Features:**
- **Shortcuts**: Use `<repo-alias> env ls` instead of `ms <repo-alias> env ls`
- **Tab Completion**: 
  - `gco <TAB>` - Complete branch names
  - `gco branch --repo <TAB>` - Complete repo aliases (or `-r <TAB>`)
  - `gco -r <repo-alias> <TAB>` - Complete branches only from the specified repo
  - Works with all git commands (gst, gco, gfo, gpu, gcob, gba, ga, gcm, gp, gfp, gd)

**Git Commands:**
- `gst` - Git status
- `gco <branch>` - Git checkout
  - `--skip-migration` - Skip database migration checks during checkout
- `gfo` - Git fetch origin
- `gpu` - Git pull
- `gcob <branch>` - Git checkout -b (create new branch)
- `gba` - Git branch -a (list all branches)
- `ga` - Git add .
- `gcm <message>` - Git commit -m
- `gp` - Git push
- `gfp --force` - Git fetch --prune and delete local branches not in origin
- `grho <branch> -r <repo>` - Git reset --hard origin/<branch>
- `g <git-args> -r <repo>` - Run any git command in specified repo(s)
- `gd` - Git diff
- `ghpr` - Create GitHub pull requests across repos
  - `--title/-t` - PR title (will prompt if not provided)
  - `--draft/-d` - Create as draft PR
  - `-r/--repo` - Specific repos (auto-discovers if not specified)
  - Requires GitHub CLI (`gh`) to be installed and authenticated
- `ghprls` - List open pull requests across repos
  - `-r/--repo` - Specific repos (lists all if not specified)
- `ghpro <number> -r <repo>` - Checkout and open a pull request
  - `<number>` - PR number to checkout
  - `-r/--repo` - Repo alias (required)
  - Uses `gh pr checkout` to fetch and checkout the PR branch
  - Requires GitHub CLI (`gh`) to be installed and authenticated

**Python Commands:**
- `venv sync` - Create/sync virtual environments using `uv`

**Docker Compose Commands** (for repos with `dockerCompose: true`):
- `<repo-alias> dcu` - Docker compose up
- `<repo-alias> dcud` - Docker compose up -d
- `<repo-alias> dcub` - Docker compose up --build
- `<repo-alias> dcd` - Docker compose down
- `<repo-alias> dcdv` - Docker compose down -v
- `<repo-alias> dcb` - Docker compose build

**Alembic Commands** (automatically uses db-alembic repo):
- `alem <command> [args...]` - Run any Alembic command
- Examples:
  - `alem current` - Show current database revision
  - `alem revision --autogenerate -m "message"` - Generate migration
  - `alem upgrade head` - Upgrade to head
  - `alem downgrade -1` - Downgrade by 1 step
  - `alem history` - Show migration history

## Usage

## Keyboard Remapping

The optional [keyd keyboard configuration](keyd/README.md) provides
Mac-like shortcuts for the built-in Ubuntu laptop keyboard.

- **Setup**: `ms setup`
- **List Env**: `ms <repo_alias> env ls` (or `<repo-alias> env ls` if integrated)
- **Modify Env**: `ms <repo_alias> env set <KEY>` (or `<repo-alias> env set <KEY>` if integrated)
- **Sync Venvs**: `ms venv sync` (or `venv sync` if integrated)
- **Docker Compose**: `<repo-alias> dcu` (or other docker commands)
- **Alembic**: `alem current` (or any alembic command - automatically uses db-alembic repo)
