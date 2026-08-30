# Changelog

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
