# Paul's dotfiles

* I maintain this repo as *my* dotfiles, but I'm keenly aware people are using it for theirs.
* You're quite welcome to make suggestions, however I may decline if it's not of personal value to me.
* If you're starting off consider forking [mathias](https://github.com/mathiasbynens/dotfiles/) or [alrra](https://github.com/alrra/dotfiles/). [paulmillr](https://github.com/paulmillr/dotfiles) and [gf3](https://github.com/gf3/dotfiles) also have great setups

## Setup
#### installing & using

* fork this to your own acct
* clone that repo with submodules: `git clone --recursive` (or `git submodule update --init` after). On the work network github.com needs the proxy, see the clone step in `setup-a-new-machine.sh`
* read and run parts of `setup-a-new-machine.sh`
* read and run `symlink-setup.sh`
  * git config needs attention, read the notes.
* copy over files that aren't in the repo: `.gitconfig.local` (gitignored, lives in the repo folder), `~/.extra`, `~/.ssh`, `~/work-cert` (`backup-old-machine.sh` collects them all)
* use it. yay!

#### maintenance

* commit/push changes you want.
* you can also hypothetically cherry-pick commits from me and mathias and our fork ecosystem.

#### shell

This repo contains config for bash, zsh, and fish. As of March 2016, I'm using fish shell mostly, but fall back to bash once in a while. The bash and fish stuff are both well maintained; zsh, less so. If you're using fish you'll want to do a `git submodule update --init`.


## my favorite parts.

### [`.aliases`](https://github.com/paulirish/dotfiles/blob/master/.aliases) and [`.functions`](https://github.com/paulirish/dotfiles/blob/master/.functions)

So many goodies.

### The "readline config" (`.inputrc`)
Basically it makes typing into the prompt amazing.

* tab like crazy for autocompletion that doesnt suck. tab all the things. srsly.
* no more <tab><tab> that says "Display all 1745 possibilities? (y or n)" YAY
* type `cat <uparrow>` to see your previous `cat`s and use them.
* case insensitivity.
* tab all the livelong day.



### Moving around in folders (`z`, `...`, `cdf`)
`z` ([zoxide](https://github.com/ajeetdsouza/zoxide)) helps you jump around to whatever folder, ranked by how often and how recently you've been there. `zi` picks from the matches with fzf. Seperately there's some `...` aliases to shorten `cd ../..` and `..`, `....` etc. Then, if you have a folder open in Finder, `cdf` will bring you to it.
```sh
z dotfiles
z blog
....      # drop back equivalent to cd ../../..
z public
cdf       # cd to whatever's up in Finder
```
`z` learns only once it's installed so you'll have to cd around for a bit to get it taught.
Lastly, I use `open .` to open Finder from this path. (That's just available normally.)



## overview of files

####  Automatic config
* `.vimrc`, `.vim` - vim config, obv.
* `.inputrc` - behavior of the actual prompt line

#### shell environment
* `.aliases`
* `.bash_profile`
* `.bash_prompt`
* `.bashrc`
* `.exports`
* `.functions`
* `.extra` - not included, explained below

#### manual run
* `setup-a-new-machine.sh` - random apps i need installed
* `backup-old-machine.sh` - backs up the old machine into `~/migration` (plus `user-info.sh` with github user and git identities, `repos.txt` with every repo under `~/GitHub` and `~/workgit`, and all of `~/.claude` plus the claude files those repos keep out of git) for `setup-a-new-machine.sh` to restore
* `symlink-setup.sh`  - sets up symlinks for all dotfiles and vim config.
* `.macos` - run on a fresh macOS setup
* `brew.sh` - homebrew initialization (`brew bundle` on `Brewfile`)

#### git, brah
* `.git`
* `.gitattributes`
* `.gitconfig`
* `.gitignore`

#### pushing to github.com and workgit

Two hosts, two accounts, same machine:

| | github.com | work.example.com |
|---|---|---|
| account | `lukap2211` | `lpuharic1` |
| network | https via `work.example.com:81` + work root cert | ssh, direct |
| login | `gh auth login -h github.com` | ssh key `~/.ssh/workgit/id_ed25519`, public half added at workgit settings/keys |
| commit identity | `Luka Puharic <lukap2211@gmail.com>` for repos under `~/GitHub/` (`.gitconfig.local`) | `Luka Puharic <work@example.com>` everywhere else |

Follows [Git on a macOS vpn system](https://work.example.com/workgit/get-started/fragments/vpn-macos-git). How it works, in plain english:

* **github.com goes over https.** ssh-style addresses (`git@github.com:...`) get rewritten to https, so the proxy and the `gh` login always apply. Git asks `gh` for the token (`!gh auth git-credential`), which keeps it in the macOS keychain.
* **workgit goes over ssh.** https addresses get rewritten to `workgit:...`, which `Host workgit` in `~/.ssh/config` maps to `git@work.example.com` with the key above. No token needed, so submodules and scripts just work.
* **anything else** (e.g. a gitlab token) is saved by the `osxkeychain` helper. Nothing is stored in plaintext (no `store` helper, no `~/.git-credentials`).
* **certificates live in `~/work-cert`** ([work CA root](https://work.example.com:8443/work_LP_CORP_CLASS_1_ROOT_G2.pem) saved as `work-root-ca.crt`, plus [`CABundle.pem`](https://work.example.com:8443/CABundle.pem), every CA work trusts). Git uses the root cert for github.com and gitlab.com; `~/.extra` points `SSL_CERT_FILE`, `REQUESTS_CA_BUNDLE`, `NODE_EXTRA_CA_CERTS` and `AWS_CA_BUNDLE` at the bundle. Re-download the bundle now and then (check it against `CABundle.pem.sha256` next to it): when the proxy moves to a new root, e.g. *work Proxy Root CA 2026 G3*, an old bundle breaks python, node, curl and aws with certificate errors.
* **which email you commit with depends on the folder**, not the host. The name is always `Luka Puharic`; the `includeIf "gitdir:~/GitHub/"` swaps in the personal email from `.gitconfig.local`.

The `~/.ssh/config` for this is in [`.ssh.config.example`](.ssh.config.example). `~/.ssh/config.d/0_bootstrap_owned.config` is work's generated config (remote-access etc.); it's deliberately not `Include`d.

Gotchas:

* don't export `GITHUB_TOKEN` in `~/.extra`. `gh` prefers it over the keychain login for github.com, and a stale one breaks pushes with "Invalid username or token".
* github.com over ssh doesn't work here: port 22 is blocked, and `ssh.github.com:443` only gets through the proxy with a helper like `socat`. Stick to https.
* if workgit git commands hang, it's the ssh agent. The workgit stanza has `IdentityAgent none` for that; `ssh -o IdentityAgent=none -T git@workgit` tells you if the key itself is fine.
* checking: `ssh -T git@workgit` should say "Hi lpuharic1!"; `gh auth status` should show github.com logged in; `git push --dry-run` tests a repo without pushing. Run ssh checks in a normal terminal, Claude Code's sandbox can't read `~/.ssh`.
* new machine: copy `~/.ssh` (with the `workgit` key) and `~/work-cert` over, run `gh auth login -h github.com`, then copy `.gitconfig.local` over.


### `.extra` for your private configuration

There will be items that don't belong to be committed to a git repo, because either 1) it shoudn't be the same across your machines or 2) it shouldn't be in a git repo. Kick it off like this:

`touch ~/.extra && $EDITOR $_`

I have some EXPORTS, my PATH construction, and a few aliases for ssh'ing into my servers in there.

I don't know how other folks manage their $PATH, but this is how I do mine:

```shell
# The top-most paths override here.
      PATH=/opt/local/bin
PATH=$PATH:/opt/local/sbin
PATH=$PATH:/bin
PATH=$PATH:~/.rvm/bin
# ...

export PATH
```


### Sensible OS X defaults

Mathias's repo is the canonical for this, but you should probably run his or mine after reviewing it.

```bash
./.macos
```

### `~/bin`

One-off binaries that aren't via an npm global or homebrew. [git open](https://github.com/paulirish/git-open), [wifi-password](https://github.com/rauchg/wifi-password), [coloredlogcat](https://developer.sinnerschrader-mobile.com/colored-logcat-reloaded/507/), and [git-overwritten](https://github.com/mislav/dotfiles/blob/master/bin/git-overwritten).

### Syntax highlighting for these files

If you edit this stuff, install [Dotfiles Syntax Highlighting](https://github.com/mattbanks/dotfiles-syntax-highlighting-st2) via [Package Control](http://wbond.net/sublime_packages/package_control)

### Colours (eza, ccat, vim)

Everything uses GitHub's dark palette. `ls` is [eza](https://github.com/eza-community/eza), `LS_COLORS` isn't used.

**eza** reads `~/.config/eza/theme.yml`, a symlink to `eza/theme.yml` (set up by `symlink-setup.sh`), which points at one of `eza/themes/`:

* `github-dark-256.yml` (active), `github-dark.yml` (truecolor)
* `monokai-256.yml`, `monokai.yml`, `gruvbox-dark.yml`, `default.yml`

```bash
# switch theme (from the repo root)
ln -sf themes/monokai.yml eza/theme.yml

# try one without switching
EZA_CONFIG_DIR=/some/dir eza -la   # /some/dir/theme.yml
```

More themes: [eza-themes](https://github.com/eza-community/eza-themes/tree/main/themes). `.exports` sets `EZA_CONFIG_DIR` (macOS otherwise looks in `~/Library/Application Support/eza`) and unsets `LS_COLORS`, which would override the theme. Per-extension colours go in `EZA_COLORS` (`man eza_colors`).

**ccat** is [bat](https://github.com/sharkdp/bat) (`bat --paging=never`). `~/.config/bat` is a symlink to `bat/` in this repo; `bat/config` picks the theme and `bat/themes/GitHub Dark.tmTheme` is a custom theme with the same colours as eza. Run `bat cache --build` after changing a theme, list themes with `bat --list-themes`.

**vim** uses [vim-github-dark](https://github.com/wojciechkepka/vim-github-dark) (`colorscheme ghdark`, closest match to the bat theme) via vim-plug, set after `plug#end()` in `.vimrc` with small overrides for selection/folds. On a new machine run `:PlugInstall` (`.vim/plugged` is gitignored).

**ghostty** reads `~/.config/ghostty`, a symlink to `ghostty/` in this repo (set up by `symlink-setup.sh`). Don't keep a config in `~/Library/Application Support/com.mitchellh.ghostty/`, ghostty loads that one last so it overrides the repo. Check it with `ghostty +validate-config`, reload with cmd+shift+, .

**iTerm** loads its settings from `iterm/com.googlecode.iterm2.plist` ("Load settings from a custom folder" in Settings → General → Settings) and saves changes back there automatically. `symlink-setup.sh` points iTerm at the folder; run it before opening iTerm on a new machine, or restart iTerm after. Changing a setting rewrites the plist, so commit it like any other dotfile.
