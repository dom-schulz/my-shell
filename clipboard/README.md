# Ghostty clipboard handoff

On X11, pasting text copied from Ghostty hangs the Chrome tab or VS Code/Cursor
window it is pasted into, and Chrome eventually kills the tab
(`Crashing because hung`). The same text pastes fine once another program
owns the clipboard.

`ghostty-clipboard-handoff` fixes this by handing Ghostty's clipboard to
`xclip`. It waits for XFixes selection-owner events instead of polling, so it
uses no CPU until something is copied. When the new clipboard owner is
Ghostty, it copies the text into `xclip`, which then answers paste requests.

Only CLIPBOARD (Ctrl+C / left Alt+C) is handed off. PRIMARY (select and
middle-click) is left alone.

## Install

`xclip` is required:

```bash
sudo apt install xclip
```

Install the script and the systemd user service, then start it:

```bash
install -Dm 0755 clipboard/ghostty-clipboard-handoff ~/.local/bin/ghostty-clipboard-handoff
install -Dm 0644 clipboard/ghostty-clipboard-handoff.service ~/.config/systemd/user/ghostty-clipboard-handoff.service
systemctl --user daemon-reload
systemctl --user enable --now ghostty-clipboard-handoff
```

The service starts with the graphical session on each login.

## Test

Check the service:

```bash
systemctl --user is-active ghostty-clipboard-handoff
```

Copy text in Ghostty and paste it into Chrome and VS Code. Neither should hang.

## Rollback

```bash
systemctl --user disable --now ghostty-clipboard-handoff
rm ~/.config/systemd/user/ghostty-clipboard-handoff.service ~/.local/bin/ghostty-clipboard-handoff
systemctl --user daemon-reload
```
