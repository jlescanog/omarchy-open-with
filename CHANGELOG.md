# Changelog

## 1.0.0

- Packaged the standalone `omarchy-browser-picker` script as an Omarchy shell
  plugin (`service` kind) with reversible `xdg-mime` registration.
- Native Omarchy menu via `omarchy menu select`, with `fuzzel` / `wofi` /
  `rofi` / `bemenu` / `dmenu` fallback.
- Profile discovery extended to Brave, Edge, Vivaldi, Opera, Thorium,
  LibreWolf, Floorp, Waterfox and Zen.
- Added per-domain routing rules, a remembered / bypassable default, and an
  opt-in private-window row per browser.
- Added `--clipboard`, `--print` and `--menu` flags and a config file at
  `~/.config/omarchy-browser-picker/config`.
- `Service.qml` exposes `open`, `clipboard`, `install`, `uninstall` and
  `status` over IPC.
