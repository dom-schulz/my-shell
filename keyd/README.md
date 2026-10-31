# keyd keyboard remapping

This configuration makes the built-in HP laptop keyboard behave more like a
Mac keyboard while leaving the Logitech K780 and right Alt unchanged.

## What it does

- Left Alt acts as Super/Meta.
- Left Super is disabled.
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
- Left Alt + 1-9 selects tabs (9 jumps to the last tab).
- Right Alt, left Ctrl, Fn, and the Logitech K780 are not remapped.

The device ID is specific to the built-in keyboard on this laptop:
`0001:0001:3ca03456`.

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
