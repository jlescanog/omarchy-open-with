# Browser Picker — Omarchy plugin

![Browser Picker menu](preview.png)

Click a link anywhere — a chat app, the terminal, a PDF — and choose **which
browser and which profile** opens it, from a native Omarchy menu. Or copy the
link instead. Or let it route itself: send `*.company.com` to your work Chrome
profile and everything else to Firefox, automatically.

This is a system-level URL handler, not a bar widget: it registers with
`xdg-mime` as the default for `http`, `https` and `text/html`.

## Features

- Native Omarchy menu (`omarchy menu select`), with a `fuzzel` / `wofi` /
  `rofi` fallback when the shell isn't running.
- Discovers **profiles** for the whole Chromium family (Chrome, Chromium,
  Brave, Edge, Vivaldi, Opera, Thorium) and the Firefox family (Firefox,
  LibreWolf, Floorp, Waterfox, Zen).
- **Copy link** entry — puts the URL on the clipboard with a notification.
- **Per-domain rules** — first match wins, globbed on the host.
- **Remembered default** — preselect a choice, or bypass the menu entirely.
- Optional **private / incognito** row per browser.
- Reversible install: the previous `xdg` default is saved and restored on
  uninstall.

## Requirements

- Omarchy 4 (`omarchy-shell`)
- `wl-clipboard` (`wl-copy` / `wl-paste`) for the copy feature
- `jq` for per-profile discovery (without it you still get one row per browser)

## Install

```bash
omarchy plugin add https://github.com/jlescanog/omarchy-browser-picker.git --enable --yes
```

Then make it your default link handler (reversible):

```bash
~/.config/omarchy/plugins/io.github.jlescanog.browser-picker/bin/browser-picker-ctl install
```

or, from the shell IPC:

```bash
omarchy-shell io.github.jlescanog.browser-picker install
```

## Uninstall

```bash
~/.config/omarchy/plugins/io.github.jlescanog.browser-picker/bin/browser-picker-ctl uninstall
omarchy plugin remove io.github.jlescanog.browser-picker
```

## Configuration

Optional. Copy [`config.example`](config.example) to
`~/.config/omarchy-browser-picker/config`:

```ini
default      = Chrome — Personal
bypass_menu  = false
show_private = false
menu         = auto
prompt       = Open with:

[rules]
*.company.com   = Chrome — Work
github.com      = Firefox — dev
localhost       = Chromium
```

Environment overrides:

| Variable | Effect |
|---|---|
| `BROWSER_PICKER_MENU=1` | force the menu even when a rule or `bypass_menu` would skip it |
| `BROWSER_PICKER_PRINT=1` | print the resolved action, run nothing |

## How it works

`bin/browser-picker-ctl install` writes
`~/.local/share/applications/io.github.jlescanog.browser-picker.desktop`
pointing at `bin/omarchy-browser-picker %u` and sets it as the `xdg-mime`
default. When any app opens a link, that script builds the browser/profile
list, shows the menu (or applies a rule), and launches the choice detached via
`systemd-run --user` + `uwsm-app`.

`Service.qml` is a thin singleton: it never intercepts links itself and runs
no long-lived process. On load it does one read-only `xdg-mime query` to know
whether it is registered; everything else happens only when you call an IPC
method (`open`, `clipboard`, `install`, `uninstall`, `status`).

## License

MIT — see [LICENSE](LICENSE).
