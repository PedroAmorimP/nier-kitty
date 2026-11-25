# Repository Guidelines

## Project Structure & Module Organization

`kitty/nier.conf` is the main dark Kitty theme; `kitty/tennoworth-light.conf` is the light variant. `shell/p10k.zsh` is an optional Powerlevel10k prompt preset. `assets/preview.png` illustrates the theme, and `licenses/powerlevel10k.txt` retains the upstream notice for the prompt preset. `kwi/*.colorscheme` (Konsole-format terminal colors) and `kwi/*.colors` (KDE window colors, including selection) adapt both themes to Kwi, KDE's experimental terminal; `docs/kwi.md` records how Kwi reads them, its limits, and safe testing. Installation and customization instructions live in `README.md`. There is no application source tree or test directory.

## Build, Test, and Development Commands

This repository contains configuration files, so there is no build or package install command. Use `kitty --config kitty/nier.conf` to preview the main theme in a new Kitty window; substitute `kitty/tennoworth-light.conf` to inspect the light variant. Run `zsh -n shell/p10k.zsh` to check prompt syntax. To test the documented installation, copy a theme into a temporary Kitty config directory, include it from `kitty.conf`, and reload Kitty with `Ctrl+Shift+F5`.

## Coding Style & Naming Conventions

Keep Kitty settings as one directive per line, grouped by purpose with brief `#` comments. Use lowercase Kitty option names and six-digit `#rrggbb` colors. The `kwi/` files are derived from the Kitty themes: when a Kitty color changes, update the matching `kwi/` entry (Konsole files use decimal `r,g,b`). Preserve the normal and bright ANSI color entries (`color0` through `color15`) and keep selection, cursor, tabs, and borders legible against each theme's background. In `shell/p10k.zsh`, follow the existing two-space indentation and `POWERLEVEL9K_` variable naming. Keep file names lowercase and descriptive. No formatter or linter is configured.

## Testing Guidelines

There is no automated test framework or coverage target. For color or tab changes, inspect the result in Kitty with ANSI colors, selected text, active and inactive tabs, and split-pane borders visible. For prompt changes, run the Zsh syntax check and start a Zsh session with Powerlevel10k loaded. For Kwi changes, check values with `kreadconfig6 --file kwi/nier.colorscheme --group Color1 --key Color`. Never test Kwi with `flatpak run org.kde.kwi` on the user's session: it is single-instance, so test launches open tabs in the user's running window. Follow the isolated nested-KWin procedure in `docs/kwi.md`, and never screenshot the host's active window. Confirm README examples still match any changed file names or settings.

## Commit & Pull Request Guidelines

The visible Git history has one commit, using a short, imperative subject: `Share NieR-inspired Kitty theme and optional Pure-style prompt`. Follow that style and describe the user-visible change. In pull requests, explain the changed theme or prompt behavior, include validation steps, and attach a screenshot for visual changes. Update `README.md` when installation or customization behavior changes, and keep the upstream notice when editing the derived prompt preset.
