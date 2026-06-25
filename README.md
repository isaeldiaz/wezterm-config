<h2 align="center">My WezTerm Config</h2>

<p align="center">
  <a href="https://github.com/KevinSilvester/wezterm-config/stargazers">
    <img alt="Stargazers" src="https://img.shields.io/github/stars/KevinSilvester/wezterm-config?style=for-the-badge&logo=starship&color=C9CBFF&logoColor=D9E0EE&labelColor=302D41">
  </a>
  <a href="https://github.com/KevinSilvester/wezterm-config/issues">
    <img alt="Issues" src="https://img.shields.io/github/issues/KevinSilvester/wezterm-config?style=for-the-badge&logo=gitbook&color=B5E8E0&logoColor=D9E0EE&labelColor=302D41">
  </a>
  <a href="https://github.com/KevinSilvester/wezterm-config/actions/workflows/lint.yml">
    <img alt="Build" src="https://img.shields.io/github/actions/workflow/status/KevinSilvester/wezterm-config/lint.yml?&style=for-the-badge&logo=githubactions&label=CI&color=A6E3A1&logoColor=D9E0EE&labelColor=302D41">
  </a>
</p>

![screenshot](./.github/screenshots/wezterm.gif)

---

### Features

- [**Background Image Selector**](https://github.com/KevinSilvester/wezterm-config/blob/master/utils/backdrops.lua)

  - Cycle images
  - Fuzzy search for image
  - Toggle background image

  > See: [key bindings](#background-images) for usage

- [**GPU Adapter Selector**](https://github.com/KevinSilvester/wezterm-config/blob/master/utils/gpu_adapter.lua)

  > :bulb: Only works if the [`front_end`](https://github.com/KevinSilvester/wezterm-config/blob/master/config/appearance.lua#L8) option is set to `WebGpu`.

  A small utility to select the best GPU + Adapter (graphics API) combo for your machine.

  GPU + Adapter combo is selected based on the following criteria:

  1.  <details>
      <summary>Best GPU available</summary>

      `Discrete` > `Integrated` > `Other` (for `wgpu`'s OpenGl implementation on Discrete GPU) > `Cpu`
      </details>

  2.  <details>
      <summary>Best graphics API available (based off my very scientific scroll a big log file in Neovim test 😁)</summary>

      > :bulb:<br>
      > The available graphics API choices change based on your OS.<br>
      > These options correspond to the APIs the `wgpu` crate (which powers WezTerm's gui in `WebGpu` mode)<br>
      > currently has support implemented for.<br>
      > See: <https://github.com/gfx-rs/wgpu#supported-platforms> for more info

      - Windows: `Dx12` > `Vulkan` > `OpenGl`
      - Linux: `Vulkan` > `OpenGl`
      - Mac: `Metal`

      </details>

- **Custom Status Bar**

  - Left status shows the active <kbd>LEADER</kbd> indicator, the current key-table
    name (e.g. `RESIZE_PANE`), and a `ZOOM` badge when the active pane is zoomed.
  - Right status shows the date/time and battery level.

- **tmux-style Leader Bindings**

  A <kbd>LEADER</kbd>-based keymap (<kbd>SUPER</kbd>+<kbd>s</kbd>) for tabs, splits,
  pane zoom/close and resize modes that mirrors a typical tmux setup.

  > See: [key bindings](#all-key-bindings) for usage

---

### Getting Started

- ##### Requirements:

  - <details>
      <summary><b>WezTerm</b></summary>

    Minimum Version: `20240127-113634-bbcac864`<br>
    Recommended Version: [`Nightly`](https://github.com/wez/wezterm/releases/nightly)

    [Official Installation Page](https://wezfurlong.org/wezterm/installation.html)

    **Windows**

    - <details>
      <summary>Install Stable</summary>

      - Install with Scoop (non-portable)

        ```sh
        scoop bucket add extras
        scoop install wezterm
        ```

      - Install with Scoop (portable)

        ```sh
        scoop bucket add k https://github.com/KevinSilvester/scoop-bucket
        scoop install k/wezterm
        ```

      - Install with winget

        ```sh
        winget install wez.wezterm
        ```

      - Install with choco

        ```sh
        choco install wezterm -y
        ```
      </details>

    - <details>
      <summary>Install Nightly</summary>

      - Install with Scoop (non-portable)

        ```sh
        scoop bucket add versions
        scoop install wezterm-nightly
        ```

      - Install with Scoop (portable)

        ```sh
        scoop bucket add k https://github.com/KevinSilvester/scoop-bucket
        scoop install k/wezterm-nightly
        ```
      </details>

    > :bulb:<br>
    > Toast notifications don't work in non-portable installations.<br>
    > See issue <https://github.com/wez/wezterm/issues/5166> for more details
  
    ---

    **MacOS**

    - <details>
      <summary>Install Stable</summary>

      - Install with Homebrew

        ```sh
        brew install --cask wezterm
        ```

      - Install with MacPort

        ```sh
        sudo port selfupdate
        sudo port install wezterm
        ```
      </details>

    - <details>
      <summary>Install Nighlty</summary>

      - Install with Homebrew

        ```sh
        brew install --cask wezterm@nightly
        ```

      - Upgrade with Homebrew

        ```sh
        brew install --cask wezterm@nightly --no-quarantine --greedy-latest
        ```
      </details>

    ---

    **Linux**

    Refer to the Linux installation page.<br>
    <https://wezfurlong.org/wezterm/install/linux.html>

    </details>

  - <details>
    <summary>JetBrainsMono Nerd Font</summary>

    Install with Homebrew (Macos)

    ```sh
    brew tap homebrew/cask-fonts
    brew install font-jetbrains-mono-nerd-font
    ```

    Install with Scoop (Windows)

    ```sh
    scoop bucket add nerd-fonts
    scoop install JetBrainsMono-NF
    ```

    > More Info:
    >
    > - <https://www.nerdfonts.com/#home>
    > - <https://github.com/ryanoasis/nerd-fonts?#font-installation>
    </details/>

&nbsp;

- ##### Steps:

  1.  ```sh
      # On Windows and Unix systems
      git clone https://github.com/KevinSilvester/wezterm-config.git ~/.config/wezterm
      ```
  2.  And Done!!! 🎉🎉

&nbsp;

- ##### Things You Might Want to Change:

  - [./config/domains.lua](./config/domains.lua) for custom SSH/WSL domains. On
    Windows these are loaded from `./config/domains_local.lua` (git-ignored), so
    create that file to add your own SSH/WSL/Unix domains without committing them.
  - [./config/launch.lua](./config/launch.lua) for preferred shells and their paths
  - [./config/fonts.lua](./config/fonts.lua) for the font family and size
    <sub>(default: JetBrainsMono Nerd Font)</sub>

---

### All Key Bindings

This config is built around a tmux-style <kbd>LEADER</kbd> key plus a small set of
direct <kbd>SUPER</kbd> shortcuts. Default key bindings are disabled
(`disable_default_key_bindings = true`), so only the bindings listed below are active.

The <kbd>SUPER</kbd> modifier maps to a physical key per OS:

- On MacOS: <kbd>SUPER</kbd> ⇨ <kbd>Cmd</kbd>
- On Windows and Linux: <kbd>SUPER</kbd> ⇨ <kbd>Alt</kbd>

> Named this way to avoid confusion when switching between OSes and to avoid<br>
> conflicting with the OS's built-in keyboard shortcuts. <sub>(A `SUPER_REV` =
> <kbd>SUPER</kbd>+<kbd>Ctrl</kbd> modifier is also defined in `bindings.lua` but
> currently unused.)</sub>

- <kbd>LEADER</kbd> ⇨ <kbd>SUPER</kbd>+<kbd>s</kbd> (i.e. <kbd>Cmd</kbd>+<kbd>s</kbd> on
  MacOS, <kbd>Alt</kbd>+<kbd>s</kbd> on Windows/Linux). After pressing the leader you
  have ~1s to press the next key. These bindings mirror a typical tmux setup.

#### Miscellaneous/Useful

| Keys                          | Action                                            |
| ----------------------------- | ------------------------------------------------- |
| <kbd>F1</kbd>                 | `ActivateCopyMode`                                |
| <kbd>F2</kbd>                 | `ActivateCommandPalette`                          |
| <kbd>F3</kbd>                 | `ShowLauncher`                                    |
| <kbd>F4</kbd>                 | `ShowLauncher` <sub>(fuzzy, tabs only)</sub>      |
| <kbd>F5</kbd>                 | `ShowLauncher` <sub>(fuzzy, workspaces only)</sub>|
| <kbd>F11</kbd>                | `ToggleFullScreen`                                |
| <kbd>F12</kbd>                | `ShowDebugOverlay`                                |
| <kbd>SUPER</kbd>+<kbd>f</kbd> | Search Text <sub>(case-insensitive)</sub>         |
| <kbd>SUPER</kbd>+<kbd>u</kbd> | Open URL <sub>(quick-select)</sub>                |

&nbsp;

#### Copy+Paste

| Keys                                          | Action               |
| --------------------------------------------- | -------------------- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>c</kbd> | Copy to Clipboard    |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> | Paste from Clipboard |

&nbsp;

#### Cursor Movements

| Keys                                   | Action                                                     |
| -------------------------------------- | ---------------------------------------------------------- |
| <kbd>SUPER</kbd>+<kbd>LeftArrow</kbd>  | Move cursor to Line Start                                  |
| <kbd>SUPER</kbd>+<kbd>RightArrow</kbd> | Move cursor to Line End                                    |
| <kbd>SUPER</kbd>+<kbd>Backspace</kbd>  | Clear Line <sub>(does not work in PowerShell or cmd)</sub> |

&nbsp;

#### Tabs

| Keys                                       | Action                                |
| ------------------------------------------ | ------------------------------------- |
| <kbd>LEADER</kbd> <kbd>n</kbd>             | `SpawnTab` <sub>(DefaultDomain)</sub> |
| <kbd>LEADER</kbd> <kbd>w</kbd>             | `CloseCurrentTab` <sub>(no confirm)</sub> |
| <kbd>LEADER</kbd> <kbd>Space</kbd>         | Next Tab                              |
| <kbd>LEADER</kbd> <kbd>Shift</kbd>+<kbd>Space</kbd> | Previous Tab                 |

&nbsp;

#### Panes

##### Panes: Split + Close

| Keys                            | Action                                           |
| ------------------------------- | ------------------------------------------------ |
| <kbd>LEADER</kbd> <kbd>\\</kbd> | `SplitHorizontal` <sub>(CurrentPaneDomain)</sub> |
| <kbd>LEADER</kbd> <kbd>-</kbd>  | `SplitVertical` <sub>(CurrentPaneDomain)</sub>   |
| <kbd>LEADER</kbd> <kbd>x</kbd>  | `CloseCurrentPane` <sub>(no confirm)</sub>       |

##### Panes: Zoom

| Keys                           | Action                |
| ------------------------------ | --------------------- |
| <kbd>LEADER</kbd> <kbd>z</kbd> | `TogglePaneZoomState` |

##### Panes: Resize

Pressing any of the keys below enters the `resize_pane` key table (see
[Key Tables](#key-tables)); <kbd>h</kbd>/<kbd>j</kbd>/<kbd>k</kbd>/<kbd>l</kbd> then
resize repeatedly until you press <kbd>q</kbd> or <kbd>Esc</kbd>.

| Keys                                              | Action                       |
| ------------------------------------------------- | ---------------------------- |
| <kbd>LEADER</kbd> <kbd>h</kbd>/<kbd>j</kbd>/<kbd>k</kbd>/<kbd>l</kbd> | Enter `resize_pane` table |

&nbsp;

#### Background Images

| Keys                                       | Action                       |
| ------------------------------------------ | ---------------------------- |
| <kbd>SUPER</kbd>+<kbd>b</kbd>             | Toggle background focus mode |
| <kbd>LEADER</kbd> <kbd>/</kbd>             | Select Random Image          |
| <kbd>LEADER</kbd> <kbd>,</kbd>             | Cycle to previous Image      |
| <kbd>LEADER</kbd> <kbd>.</kbd>             | Cycle to next Image          |
| <kbd>LEADER</kbd> <kbd>Shift</kbd>+<kbd>/</kbd> | Fuzzy select Image      |

&nbsp;

#### Misc (Leader)

| Keys                           | Action                                       |
| ------------------------------ | -------------------------------------------- |
| <kbd>LEADER</kbd> <kbd>r</kbd> | `ReloadConfiguration`                        |
| <kbd>LEADER</kbd> <kbd>m</kbd> | Toggle mouse mode <sub>(enable/disable)</sub> |
| <kbd>LEADER</kbd> <kbd>f</kbd> | Enter `resize_font` key table                |

&nbsp;

#### Key Tables

> See: <https://wezfurlong.org/wezterm/config/key-tables.html>

| Keys                           | Action                          | Timeout |
| ------------------------------ | ------------------------------- | ------- |
| <kbd>LEADER</kbd> <kbd>f</kbd> | enter `resize_font`             | 8s      |
| <kbd>LEADER</kbd> <kbd>h</kbd>/<kbd>j</kbd>/<kbd>k</kbd>/<kbd>l</kbd> | enter `resize_pane` | 1s |

##### Key Table: `resize_font`

| Keys           | Action                          |
| -------------- | ------------------------------- |
| <kbd>k</kbd>   | `IncreaseFontSize`              |
| <kbd>j</kbd>   | `DecreaseFontSize`              |
| <kbd>r</kbd>   | `ResetFontSize`                 |
| <kbd>q</kbd>   | `PopKeyTable` <sub>(exit)</sub> |
| <kbd>Esc</kbd> | `PopKeyTable` <sub>(exit)</sub> |

##### Key Table: `resize_pane`

| Keys           | Action                                         |
| -------------- | ---------------------------------------------- |
| <kbd>k</kbd>   | `AdjustPaneSize` <sub>(Direction: Up)</sub>    |
| <kbd>j</kbd>   | `AdjustPaneSize` <sub>(Direction: Down)</sub>  |
| <kbd>h</kbd>   | `AdjustPaneSize` <sub>(Direction: Left)</sub>  |
| <kbd>l</kbd>   | `AdjustPaneSize` <sub>(Direction: Right)</sub> |
| <kbd>q</kbd>   | `PopKeyTable` <sub>(exit)</sub>                |
| <kbd>Esc</kbd> | `PopKeyTable` <sub>(exit)</sub>                |

&nbsp;

#### Mouse

Default mouse bindings are kept enabled; the following are customized:

| Event                                         | Action                                          |
| --------------------------------------------- | ----------------------------------------------- |
| Left-click release                            | Copy selection to Clipboard + Primary Selection |
| <kbd>Ctrl</kbd>+Left-click                    | Open link under cursor                          |
| Mouse wheel <sub>(MacOS only)</sub>           | Scroll viewport                                 |

> Mouse mode can be toggled off/on at runtime with <kbd>LEADER</kbd> <kbd>m</kbd>.

---

### References/Inspirations

- <https://github.com/rxi/lume>
- <https://github.com/catppuccin/wezterm>
- <https://github.com/wez/wezterm/discussions/628#discussioncomment-1874614>
- <https://github.com/wez/wezterm/discussions/628#discussioncomment-5942139>
