# keyd keyboard remapping

This configuration makes the built-in HP laptop keyboard and the Logitech K780
behave more like a Mac keyboard while leaving right Alt unchanged.

## What it does

- Left Alt acts as Super/Meta.
- Left Super (where Option is on a Mac) is an Option-style layer:
  - Left Super + Left/Right jumps by word; add Shift to select by word.
  - Left Super + Backspace/Delete deletes by word.
- Ctrl + Left Super + Left/Right snaps the window to the left/right half,
  and Up maximizes. These match Rectangle's Ctrl + Option keys.
- Ctrl + Left Super + Left Alt + Left/Right moves the window to the other
  monitor, matching Rectangle's Ctrl + Option + Cmd keys.
- Left Alt opens GNOME overview/search.
- Left Alt + C/V/X maps to copy/paste/cut.
- Left Alt + A/Z maps to select all/undo.
- Left Alt + Shift + Z maps to redo.
- Left Alt + S/F maps to save/find.
- Left Alt + L maps to Ctrl+L, including Chrome's address bar.
- Left Alt + Shift + L maps to Super+L, which locks the screen in GNOME.
- Left Alt + N maps to new window, including Ghostty via its Ctrl+N keybind.
- Left Alt + T/W maps to new tab/close tab or window, including Ghostty via its
  Ctrl+W keybind.
- Left Alt + D splits a Ghostty pane right, and Left Alt + Shift + D splits it
  down. They send Ctrl+Alt+Super+D and Ctrl+Alt+Shift+Super+D, which only
  Ghostty binds, so they do nothing in other apps.
- Left Alt + Left/Right jumps to the start/end of the line, Up/Down to the
  top/bottom of the document; add Shift to select. Left Alt + Backspace
  deletes to the start of the line.
- Left Alt + Left Super + arrows move between Ghostty splits.
- Left Alt + 1-9 selects tabs (9 jumps to the last tab).
- Right Alt, left Ctrl, and Fn are not remapped.

The device IDs match by vendor and product only: the built-in keyboard
(`0001:0001`) and the Logitech K780 over its Unifying receiver (`046d:405b`)
and Bluetooth (`046d:b33b`). The K780 must be in PC mode (Fn+P); Mac mode
swaps the keys next to the space bar. keyd's full IDs include a trailing hash
(`0001:0001:xxxxxxxx`) that can change after a kernel update or reboot, which
makes keyd silently ignore the keyboard. If remaps stop working, run
`journalctl -u keyd -b` and look for `DEVICE: ignoring ... (AT Translated Set 2
keyboard)`.

## Install

Ubuntu 24.04 requires the keyd PPA:

```bash
sudo add-apt-repository ppa:keyd-team/ppa
sudo apt update
sudo apt install keyd
```

Install this configuration and reload keyd:

```bash
backup="/etc/keyd.backup-$(date +%Y%m%d-%H%M%S)"
sudo cp -a /etc/keyd "$backup"
sudo install -m 0644 keyd/default.conf /etc/keyd/default.conf
sudo /usr/bin/keyd.rvaiya reload
```

The keyd service is enabled by the package and persists across reboots.

## Test

Check the service:

```bash
systemctl is-active keyd
```

Test in a text editor and browser. Left Alt alone should open GNOME overview
and search; Alt+L should focus Chrome's address bar.

## Rollback

Restore the most recent backup, then reload:

```bash
sudo rm /etc/keyd/default.conf
sudo /usr/bin/keyd.rvaiya reload
```

To restore a prior configuration instead:

```bash
sudo cp -a /etc/keyd.backup-YYYYMMDD-HHMMSS/. /etc/keyd/
sudo /usr/bin/keyd.rvaiya reload
```
