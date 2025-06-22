
# Dotfiles

🏠 Personal dotfiles for \*NIX (macOS and Linux) systems.


## Installation

### 👉 One-liner (if you trust me):

```bash
curl -fsSL https://dotfiles.wook.kr/etc/install | bash
```

<details><summary>
💡 (Tip) You only need to remember <code>curl dotfiles.wook.kr</code> (Click to expand)
</summary></p>

* Every file is accessible through `dotfiles.wook.kr` (via `curl -L` or `wget`), e.g.,
  * https://dotfiles.wook.kr/vimrc
  * https://dotfiles.wook.kr/vimrc?raw=true
  * https://dotfiles.wook.kr/bin/tb

<p></details>

<details><summary>
🤔 Want to manually clone and install? (Click to expand)
</summary><p>

```bash
$ git clone --recursive https://github.com/wookayin/dotfiles.git ~/.dotfiles
$ cd ~/.dotfiles && python install.py
```

<!--
Note: The option `-j8` (`--jobs 8`) works with Git >= 2.8 (parallel submodule fetching).
For older versions of Git, try without `-j` option.
-->

</p></details>

<br>


The installation script will clone the repository into `~/.dotfiles` and create symbolic links (e.g., `~/.vimrc`) for you.
If target files already exist (e.g. `~/.vim`, `~/.vimrc`), you will need to manually resolve the conflict (delete the old one or just ignore). See Troubleshooting below for details.


## `$ dotfiles`

**To update dotfiles** (pull changes from upstream and run [`install.py`][install.py] again):

```bash
$ dotfiles update
$ dotfiles update --fast          # fast update mode: skip updating {vim,zsh} plugins
```

On Linux, you can [install some common softwares locally][linux-locals.sh] (into `$HOME/.local/bin`) *without sudo*:

```bash
$ dotfiles install neovim         # -> ~/.local/bin/nvim
$ dotfiles install ripgrep        # -> ~/.local/bin/rg
```



## 🆘 Troubleshooting

*Please read carefully warning messages during installation !!*

* If something goes wrong, please run **[`$ dotfiles update`][dotfiles-update]** (or [install.py]) to make everything up-to-date.
    * Please carefully READ the error/warning message printed by the installation script.
    * If you have your own `~/.zshrc`, `~/.vimrc`, `~/.vim`, etc., that are NOT symbolic links,
      they will not be overwritten by default.
      In such cases you should delete these files *manually*.

* Q: I see some weird icons like `⍰` in (neo)vim or in the [statusline](https://github.com/powerline/powerline#vim-statusline).
  - A: Use [Nerd fonts](https://github.com/ryanoasis/nerd-fonts) v3. If you haven't upgrade to Nerd fonts [**v3.1.1** or higher](https://github.com/ryanoasis/nerd-fonts/releases/tag/v3.1.1), upgrade to v3 due to the new (breaking) Material Design Icons codepoints.
    - Note: `JetBrainsMono Nerd Font Mono` ~~`JetBrainsMono NFM`~~ (nerd-fonts [v3.1.0 is buggy](https://github.com/ryanoasis/nerd-fonts/issues/1434))
  - Mac users can install via: `brew install --cask font-*-nerd-font`.
    - (Minimal fonts only `brew install --cask font-jetbrains-mono-nerd-font`)
  - To upgrade existing installations, try `brew reinstall --cask $(brew list | grep nerd-font)`.

* If neovim + treesitter emits an error like `query: invalid node type`, run `:TSUpdate` (and wait for installation is done).
  * See [nvim-treesitter#3092](https://github.com/nvim-treesitter/nvim-treesitter/issues/3092) for more details.

* If neovim cannot run due to `version 'GLIBC_2.29' not found` errors (on Ubuntu 18.04 or earlier),
  you should upgrade your Ubuntu distribution to 20.04+ in order to run nvim 0.8.x or higher.
  If you use [appimage](https://github.com/neovim/neovim/releases/tag/stable) binary of neovim,
  this will work in Ubuntu 18.04; install neovim through `dotfiles install neovim` or `NEOVIM_VERSION=0.9.4 dotfiles install neovim`.

* If [**neovim**][neovim] emits any startup errors (e.g. `no module named neovim`):
    * Use **latest neovim** (e.g., neovim 0.11.0).
      To install/upgrade neovim on your system, you can run `dotfiles install neovim` (linux) or `brew install neovim` (mac).
    * Try `:checkhealth`.
    * Try `:Lazy update`: some errors from vim plugin could be easily solved by updating plugins to date.
      You can do `:Lazy update` (in vim) or `$ dotfiles update` (in zsh).
    * We require python3 version not less than 3.6. See https://endoflife.date/python
    * Make sure that the [`pynvim`](https://pypi.python.org/pypi/pynvim/) pypi package is installed on *local* python 3,
      i.e. the python3 on conda, virtualenv, etc.
      This should have been automatically installed.
      If it doesn't work, check `which python3`. Use the following vim command to tell which host python is used:
          [`:echo g:python3_host_prog`](https://github.com/wookayin/dotfiles/blob/master/nvim/init.vim).
      * If you are not sure, manually running `python3 -m pip install --user pynvim` might help.

* Does vim color look weird (e.g. only black-and-white)?
  * Check whether your terminal emulator supports [24-bit color](https://github.com/wookayin/dotfiles/pull/9). Use iTerm2, wezterm, or kitty; NOT built-in Terminal.
  * Latest Mosh (1.4.0+) support 24-bit colors, so try upgrading mosh if you are using it.
  * Try `:set notermguicolors` to temporarily disable 24-bit colors.
* Does tmux look weird? Make sure that tmux version is [2.3](etc/ubuntu-setup.sh) or higher.
    * Run `$ dotfiles install tmux` to install `tmux` into `$HOME/.local/bin`, if you do not have sudo.
* If you are still lost, or you've found a bug, please feel free to contact me or raise an issue ---
  I will happy to assist.


[neovim]: https://github.com/neovim/neovim
[dotfiles-update]: https://github.com/wookayin/dotfiles/blob/master/bin/dotfiles
[linux-locals.sh]: https://github.com/wookayin/dotfiles/blob/master/etc/linux-locals.sh
[install.py]: https://github.com/wookayin/dotfiles/blob/master/install.py


## License

[The MIT License (MIT)](LICENSE)

Copyright (c) 2012-2025 Jongwook Choi (@wookayin)
