# `Oh my ZSH!` and `Node.js` setup script
Basic bash script for workspace setup. It installs basic packages such as `git` and sets up `zsh` with `Oh my ZSH!`

### Main features
- Populating `sudoers` to enable paswordless sudo for easy setup
- `git` and `global account identity` setup
- `zsh` as a basic shell
- `Oh my ZSH!` with plugins
  - `zsh-nvm`
  - `zsh-syntax-highlighting`
  - `zsh-autosuggestions`
- `Powerlevel10k` theme
- Alias setup
- Latest **lts** `node` and `yarn` setup
- `FiraCode` font
- `snap` apps such as
  - `vscode-insiders`
  - `spotify`
  - `slack`
  - `postman`
- Generating `ssh` key and adding it to `GitHub` account

## Installation
```bash
bash -c "$(wget -O- https://szymmis.github.io/setup/setup.sh)" 
```

## Configuration
You can easly change which **plugins**, **aliases**, **snaps** and **theme** is installed by modyfing the arrays entries
```bash
PLUGINS=("https://github.com/lukechilds/zsh-nvm.git" "..." "...")
THEME="https://github.com/romkatv/powerlevel10k.git"
ALIASES=("code='code-insiders'" "zshrc='nano ~/.zshrc'")
SNAPS=("code-insiders" "..." "..." "...")
```
