# Kwi review

Reviewed on 2026-11-24 against Kwi source commit `d9b8ca4` ([invent.kde.org/utilities/kwi](https://invent.kde.org/utilities/kwi)) and the nightly Flatpak `org.kde.kwi` 0.1.0 (built 2026-11-22). Kwi is KDE's experimental terminal, built on Qt Quick, Kirigami and libghostty-vt. It is in KDE Review; expect the behavior below to change.

## How Kwi colors a terminal

| Source | What it controls | Where Kwi reads it |
| --- | --- | --- |
| Konsole `.colorscheme` (KConfig INI) | `[Foreground]`, `[Background]`, `[ForegroundIntense]` (bold text), `[Color0]`–`[Color7]` and `[Color0Intense]`–`[Color7Intense]`, `[General] Description` | `$XDG_DATA_HOME/kwi/color-schemes/` (listed as `imported:`), `…/kwi/color-schemes/user/` (what the in-app importer and editor write, with UUID file names), and every `konsole/` data directory (read-only) |
| KDE window `.colors` scheme | Tabs and other chrome, **selection** (`[Colors:Selection]`), the search highlight (a 35% mix of View background and Selection) | `$XDG_DATA_HOME/color-schemes/`, chosen per app under **Colors → Window** |

Source: `libs/kwi-terminal/src/TerminalColors.cpp` (`loadTerminalPaletteFile`) and `src/settings/TerminalPaletteModel.cpp`. Settings live in `kwiterminalrc` (`[Appearance] ColorScheme=imported:nier.colorscheme`).

In the Flatpak, `$XDG_DATA_HOME` is `~/.var/app/org.kde.kwi/data`, and host `~/.local/share/konsole` is **not** on its data path. Kwi watches its terminal scheme directories with KDirWatch, so new terminal schemes appear without a restart; a newly created window-scheme directory may need one.

## Not configurable (as of this review)

- **Cursor color.** `TerminalView::applyColors()` always passes an invalid cursor color, so the cursor takes the color of the cell under it. OSC 12 from the shell (`printf '\e]12;#e8b968\a'`) should still set it through libghostty-vt; not yet tested.
- **Faint text.** `Color*Faint` and `Background*` variants are ignored. The `kwi/*.colorscheme` files keep them for Konsole.
- **Colors 16–255.** Kwi keeps libghostty-vt's xterm defaults; there is no equivalent of Kitty's `palette_generate`. OSC 4 from the shell could load Kitty's generated palette; not yet tested.
- **Marks, split-pane borders.** Kwi has neither; split panes are planned upstream.
- **Custom shaders.** The terminal shader (`libs/ghostty-qt-quick/src/shaders/terminal.frag`) is compiled into the binary. Ghostty's `custom-shader` belongs to Ghostty's renderer, which Kwi does not use. The YoRHa input shimmer is therefore Kitty-only.

## Options for the YoRHa shimmer later

1. **KWin effect.** An `OffscreenEffect` plugin that applies the YoRHa shader to windows of class `org.kde.kwi`, matching `#302d2a` and pi's rules on `#14110d` as the Kitty shader does. Works with the unmodified Flatpak but must be rebuilt for each KWin update, and must skip the tab bar because `nier.colors` also uses `#14110d` there. Needs `extra-cmake-modules` and KWin headers.
2. **Patched Kwi.** A `layer.effect` `ShaderEffect` on `TerminalView` in `libs/kwi-terminal/src/declarative/Terminal.qml`. Clean, but means running a self-built Kwi (Qt 6.11+, KF 6.29+, libghostty-vt 1.0.1+).
3. **Upstream.** Propose a custom-shader option, and reading a cursor color from scheme files, to the Kwi developers (`#kwi:kde.org` on Matrix).

## Testing Kwi safely

- Kwi is a unique D-Bus service: `flatpak run org.kde.kwi …` and `--new-tab` open tabs **in the user's running window** and ignore test `XDG_*` overrides. Never test that way on a live session.
- Kwi runs standalone when it cannot claim its bus name (`KDBusService::Unique | NoExitOnFailure`). Running `dbus-run-session -- kwin_wayland --virtual --no-lockscreen --width 1400 --height 820 --exit-with-session '…'` gives an isolated compositor and bus; `spectacle -b -n -f -o file.png` inside it captures only that session.
- Do not use `spectacle -a` from the host session: it captures whichever window is active.
- A private bus can activate its own `xdg-document-portal`, and the host's `/run/user/$UID/doc` mount was found missing after such runs. Flatpak apps fail to start without it; `systemctl --user restart xdg-document-portal.service` restores it. Check the mount after testing.
- `--env=XDG_CONFIG_HOME/XDG_DATA_HOME` overrides did not take effect in the isolated run (Kwi showed stock Breeze), so the schemes have not been visually verified in an isolated session. They were verified by KConfig round-trip (`kreadconfig6`) against the Kitty values, and by eye in the user's own Kwi.
