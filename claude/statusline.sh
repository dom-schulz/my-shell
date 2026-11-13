#!/usr/bin/env bash
# Claude Code status line, adapted from github.com/daniel3303/ClaudeCodeStatusLine.
# Model (effort) | dir@branch (+/-) | tokens/size (pct) | 5h pct | 7d pct
# Uses only the JSON Claude Code passes on stdin; no network calls.

input=$(cat)

# Mid-tone colors chosen to stay readable on both light and dark backgrounds.
blue='\033[38;2;30;120;220m'
orange='\033[38;2;215;100;20m'
green='\033[38;2;20;140;60m'
cyan='\033[38;2;0;130;140m'
red='\033[38;2;210;50;50m'
yellow='\033[38;2;175;125;0m'
purple='\033[38;2;130;80;220m'
label='\033[1m'
dim='\033[2m'
reset='\033[0m'
sep=" ${dim}|${reset} "

format_tokens() {
    local n=$1
    if [ "$n" -ge 1000000 ]; then
        awk "BEGIN {v=sprintf(\"%.1f\",$n/1000000)+0; if(v==int(v)) printf \"%dm\",v; else printf \"%.1fm\",v}"
    elif [ "$n" -ge 1000 ]; then
        awk "BEGIN {printf \"%.0fk\", $n/1000}"
    else
        printf "%d" "$n"
    fi
}

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

# dir@branch (+added -deleted); in a linked worktree: repo@branch, worktree dir on line 2
if [ -n "$cwd" ]; then
    { read -r branch; read -r git_dir; read -r common_dir; read -r toplevel; } < <(
        git -C "$cwd" rev-parse --path-format=absolute --abbrev-ref HEAD --git-dir --git-common-dir --show-toplevel 2>/dev/null
    )
    if [ -n "$git_dir" ] && [ "$git_dir" != "$common_dir" ]; then
        repo=${common_dir%/.git}
        out+="${sep}${cyan}${repo##*/}${reset}"
        line2="${dim}worktree:${reset} ${yellow}${toplevel##*/}${reset}"
    else
        out+="${sep}${cyan}${cwd##*/}${reset}"
    fi
    if [ -n "$branch" ]; then
        out+="${dim}@${reset}${green}${branch}${reset}"
        stat=$(git -C "$cwd" diff --numstat 2>/dev/null | awk '{a+=$1; d+=$2} END {if (a+d>0) printf "+%d -%d", a, d}')
        [ -n "$stat" ] && out+=" ${dim}(${reset}${green}${stat%% *}${reset} ${red}${stat##* }${reset}${dim})${reset}"
    fi
fi

# Context tokens
out+="${sep}${orange}$(format_tokens "$current")/$(format_tokens "$size")${reset} ${dim}(${reset}$(usage_color "$pct_used")${pct_used}%${reset}${dim})${reset}"

# Faint grey for unused bar segments, matched to the macOS appearance Ghostty follows.
if [ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" ]; then
    empty='\033[38;2;58;60;66m'
else
    empty='\033[38;2;218;220;225m'
fi

# 10-segment bar: one segment per 10% used, filled in a muted usage color, rest faint grey.
usage_bar() {
    local pct=$1 color filled i bar=""
    # Muted versions of usage_color so the bar reads softer than the percentage.
    if   [ "$pct" -ge 90 ]; then color='\033[38;2;205;120;120m'
    elif [ "$pct" -ge 70 ]; then color='\033[38;2;215;150;105m'
    elif [ "$pct" -ge 50 ]; then color='\033[38;2;195;165;85m'
    else color='\033[38;2;110;165;120m'
    fi
    filled=$(( (pct + 5) / 10 ))
    [ "$filled" -gt 10 ] && filled=10
    for (( i = 0; i < 10; i++ )); do
        if [ "$i" -lt "$filled" ]; then bar+="${color}▉${reset}"; else bar+="${empty}▉${reset}"; fi
    done
    echo "$bar"
}

# Rate limits (usage only)
for pair in "5h:$five_pct" "7d:$seven_pct"; do
    name=${pair%%:*}; pct=${pair#*:}
    [ -z "$pct" ] && continue
    pct=$(printf "%.0f" "$pct")
    out+="${sep}${label}${name}${reset} $(usage_bar "$pct") $(usage_color "$pct")${pct}%${reset}"
done

[ -n "$line2" ] && out+="\n${line2}"
printf "%b" "$out"
