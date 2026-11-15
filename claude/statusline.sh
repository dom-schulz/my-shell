#!/usr/bin/env bash
# Claude Code status line, adapted from github.com/daniel3303/ClaudeCodeStatusLine.
# Model (effort) | dir@branch (+/-) | tokens/size (pct) | 5h pct | 7d pct
# Uses only the JSON Claude Code passes on stdin; no network calls.

input=$(cat)

# Mid-tone colors chosen to stay readable on both light and dark backgrounds.
blue='\033[38;2;30;120;220m'
orange='\033[38;2;215;100;20m'
green='\033[92m'   # palette bright green: vivid in both ghostty themes
dir_blue='\033[01;34m'  # bold palette blue, the old directory color
red='\033[38;2;210;50;50m'
yellow='\033[38;2;175;125;0m'
purple='\033[1;38;2;130;80;220m'
label='\033[1m'
dim='\033[2m'
reset='\033[0m'
sep=" ${dim}|${reset} "

usage_color() {
    if   [ "$1" -ge 90 ]; then echo "$red"
    elif [ "$1" -ge 70 ]; then echo "$orange"
    elif [ "$1" -ge 50 ]; then echo "$yellow"
    else echo "$green"
    fi
}

IFS=$'\x1f' read -r model_name size input_tokens cache_create cache_read effort cwd five_pct seven_pct <<<"$(
    echo "$input" | jq -r '[
        (.model.display_name // "Claude"),
        (.context_window.context_window_size // 200000),
        (.context_window.current_usage.input_tokens // 0),
        (.context_window.current_usage.cache_creation_input_tokens // 0),
        (.context_window.current_usage.cache_read_input_tokens // 0),
        (.effort.level // ""),
        (.workspace.current_dir // .cwd // ""),
        (.rate_limits.five_hour.used_percentage // "" | tostring),
        (.rate_limits.seven_day.used_percentage // "" | tostring)
    ] | map(tostring) | join("\u001f")'
)"

model_name=$(echo "$model_name" | sed 's/ *(\([0-9.]*[kKmM]*\) context)/ \1/')
[ "$size" -gt 0 ] 2>/dev/null || size=200000
current=$(( input_tokens + cache_create + cache_read ))
pct_used=$(( current * 100 / size ))

if [ -z "$effort" ]; then
    effort="${CLAUDE_CODE_EFFORT_LEVEL:-$(jq -r '.effortLevel // empty' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" 2>/dev/null)}"
fi

# Model (effort)
out="${purple}${model_name}${reset}"
[ "$effort" = "medium" ] && effort="med"
[ -n "$effort" ] && out+=" ${dim}(${effort})${reset}"

# repo@branch (+added -deleted); full directory path on line 2.
# The repo name comes from the shared .git dir, so worktrees show their parent repo.
if [ -n "$cwd" ]; then
    { read -r branch; read -r common_dir; } < <(
        git -C "$cwd" rev-parse --path-format=absolute --abbrev-ref HEAD --git-common-dir 2>/dev/null
    )
    name=${cwd##*/}
    [ -n "$common_dir" ] && { repo=${common_dir%/.git}; name=${repo##*/}; }
    out+="${sep}${dir_blue}${name}${reset}"
    line2="${dim}${cwd/#$HOME/~}${reset}"
    if [ -n "$branch" ]; then
        out+="${dim}@${reset}${green}${branch}${reset}"
        stat=$(git -C "$cwd" diff --numstat 2>/dev/null | awk '{a+=$1; d+=$2} END {if (a+d>0) printf "+%d -%d", a, d}')
        [ -n "$stat" ] && out+=" ${dim}(${reset}${green}${stat%% *}${reset} ${red}${stat##* }${reset}${dim})${reset}"
    fi
fi

# Pie glyph in quarter steps: empty, 1/4, 1/2, 3/4, full.
usage_pie() {
    local pies=(○ ◔ ◑ ◕ ●) i=$(( ($1 + 12) / 25 ))
    [ "$i" -gt 4 ] && i=4
    echo "${pies[$i]}"
}

# Context gets tighter thresholds than rate limits: yellow over 20%, orange over 30%, red over 40%.
ctx_color() {
    if   [ "$1" -gt 40 ]; then echo "$red"
    elif [ "$1" -gt 30 ]; then echo "$orange"
    elif [ "$1" -gt 20 ]; then echo "$yellow"
    else echo "$green"
    fi
}

# Context tokens
out+="${sep}${label}ctx${reset} $(ctx_color "$pct_used")$(usage_pie "$pct_used") ${pct_used}%${reset}"

# Rate limits (usage only)
for pair in "5h:$five_pct" "7d:$seven_pct"; do
    name=${pair%%:*}; pct=${pair#*:}
    [ -z "$pct" ] && continue
    pct=$(printf "%.0f" "$pct")
    out+="${sep}${label}${name}${reset} $(usage_color "$pct")$(usage_pie "$pct") ${pct}%${reset}"
done

[ -n "$line2" ] && out+="\n${line2}"
printf "%b" "$out"
