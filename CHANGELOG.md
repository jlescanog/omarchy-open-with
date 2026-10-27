# Changelog

## 1.0.1

Works with Omarchy 4, where links stopped reaching the menu.

- Omarchy now routes links through `~/.config/hyprland-mimeapps.list`, read
  before `mimeapps.list`, so the `xdg-mime` handler was ignored. `install`
  registers `https` and `text/html` there and `uninstall` restores the previous
  lines exactly. `http` and `mimeapps.list` are left alone so Omarchy still finds
  the real browser for Super+B and web apps.
- Terminal programs (`codex login`, `gh auth login`...) open `$BROWSER`, not the
  xdg handler. `install` adds a guarded block to `~/.bashrc` pointing `$BROWSER`
  at the picker; `uninstall` removes it.
- `status` reports correctly under Omarchy's desktop-specific list.
- Upgrading from 1.0.0 hands `mimeapps.list` back to a real browser instead of
  `omarchy-browser.desktop`.
- Tests cover install/uninstall against a throwaway XDG tree and `~/.bashrc`.

## 1.0.0

First release. A `service`-kind Omarchy plugin that registers a reversible
`xdg-mime` handler for http/https/text-html and shows a native menu to pick a
browser + profile, or copy the link.

- Profile discovery for Chrome, Chromium, Brave, Edge, Vivaldi, Opera, Thorium,
  Firefox, LibreWolf, Floorp, Waterfox and Zen. Only installed browsers appear.
- Native Omarchy menu, with `fuzzel` / `wofi` / `rofi` / `bemenu` / `dmenu`
  fallback. One backend per invocation — a cancelled menu never opens another.
- `Copy link` row.
- Browsers are launched through a real argument vector, so profile names
  containing quotes, spaces or semicolons are never re-parsed as shell input.
- The install/uninstall helper never follows a symlink at its target paths and
  writes the desktop file with explicit `644` permissions.
- `Service.qml` exposes `open`, `clipboard`, `install`, `uninstall`, `status`.
