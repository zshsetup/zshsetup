#!/usr/bin/env zsh
# shellcheck shell=bash
# the environment of zshsetup, read by every zsh, also by scripts and `ssh host cmd`: it only
# sets variables, PATH, and fpath, without installing anything, prompting, or printing
# .zshrc reads it too when it is not linked yet, as the install does
# expects $HOME to be set

export ZSHSETUP_REPO="${ZSHSETUP_REPO:-https://github.com/zshsetup/zshsetup}"
export ZSHSETUP_HOME="$HOME/.config/zshsetup"

# SETUP XDG SPEC
export LOCAL_HOME="$HOME/.local"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$LOCAL_HOME/share"
export XDG_BIN_HOME="$LOCAL_HOME/bin"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$LOCAL_HOME/state"

# systemd / macOS runtime dir
if [[ ! -d "$XDG_RUNTIME_DIR" ]]; then
  if [[ -d "/run/user/$UID" ]]; then
    export XDG_RUNTIME_DIR="/run/user/$UID"
  elif [[ "$OSTYPE" == darwin* ]] && [[ -n "$TMPDIR" ]]; then
    export XDG_RUNTIME_DIR="${TMPDIR%/}"
  fi
fi

# SETUP HISTORY
# /etc/zshrc of macOS sets these after this file, .zshrc reads it again after that
HISTFILE="$ZSHSETUP_HOME/zsh_history"
HISTSIZE=200000
# shellcheck disable=SC2034
SAVEHIST=100000

# SETUP OH-MY-ZSH
export ZSH="$ZSHSETUP_HOME/oh-my-zsh"
# shellcheck disable=SC2034
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"
# shellcheck disable=SC2034
ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump-${HOST%%.*}-${ZSH_VERSION}"
# shellcheck disable=SC2034
ZSH_CUSTOM="$ZSH/custom"
# shellcheck disable=SC2034
ZSH_THEME="robbyrussell"

# drops duplicate PATH and FPATH entries, also when this file is read again
typeset -gU path fpath

# user bin before system PATH, but after toolchains and Homebrew
path=("$HOME/bin" "${path[@]}")

# HOMEBREW
# before oh-my-zsh, whose compinit only sees the site-functions of Homebrew already in fpath;
# .zshrc offers to install Homebrew, and reads this file again once it is there
# the output of `brew shellenv`, written out as running it forks and costs about 12ms in every zsh
# (its MANPATH step does nothing here, as MANPATH is set below)
if [[ -f /opt/homebrew/bin/brew ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"
  fpath=("/opt/homebrew/share/zsh/site-functions" "${fpath[@]}")
  path=("/opt/homebrew/bin" "/opt/homebrew/sbin" "${path[@]}")
  export FPATH
  if [[ ":$INFOPATH" != *:/opt/homebrew/share/info:* ]]; then
    export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
  fi
fi

# mandoc (Alpine) does not find man pages next to the bin dirs in PATH, the trailing colon keeps
# the defaults
export MANPATH="$XDG_DATA_HOME/man:"
# the environment and PATH entries of packages like go and rustup
[[ -f "${PMG_HOME:-$XDG_DATA_HOME/pmg}/env.sh" ]] && . "${PMG_HOME:-$XDG_DATA_HOME/pmg}/env.sh"

# GO
# for go from other package managers, pmg sets GOROOT, GOPATH, and PATH in its env file
export GOPATH="${GOPATH:-$XDG_DATA_HOME/go}"
path=("$GOPATH/bin" "${path[@]}")

# RUST
# for rustup from other package managers, pmg sets RUSTUP_HOME, CARGO_HOME, and PATH in its env
# file
export RUSTUP_HOME="${RUSTUP_HOME:-$XDG_DATA_HOME/rustup}"
export CARGO_HOME="${CARGO_HOME:-$XDG_DATA_HOME/cargo}"
path=("$CARGO_HOME/bin" /opt/homebrew/opt/rustup/bin "${path[@]}")

# JAVASCRIPT
export BUN_INSTALL="$XDG_DATA_HOME/bun"
export BUN_INSTALL_CACHE_DIR="$XDG_CACHE_HOME/bun/install"
export BUN_RUNTIME_TRANSPILER_CACHE_PATH="$XDG_CACHE_HOME/bun/runtime"
export BUN_CONFIG_DIR="$XDG_CONFIG_HOME/bun"
path=("$BUN_INSTALL/bin" "${path[@]}")

# SETUP PATH
# the links of zshsetup (e.g. pmg) come first, then the bin directories of the plugins, then
# the commands of pmg in $XDG_BIN_HOME before those of Homebrew and the toolchains
# .zprofile moves them to the front again, after /etc/zprofile
path=("$ZSHSETUP_HOME/bin" "$ZSHSETUP_HOME"/plugins/*/bin(N) "$XDG_BIN_HOME" "${path[@]}")
export PATH

# SETUP OTHER ENVIRONMENT
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export MPLCONFIGDIR="$XDG_CONFIG_HOME/matplotlib"
export PYTHON_HISTORY="$XDG_DATA_HOME/python/python_history"
# without system certificates, git and micromamba use the ones bundled with git-static
() {
  local -a git_certs system_certs
  git_certs=("${PMG_HOME:-$XDG_DATA_HOME/pmg}"/packages/git@*/share/git-core/certs(N[-1]))
  system_certs=(/etc/ssl/certs/*(NY1))
  if [[ ! -e /etc/ssl/cert.pem ]] && (( ! ${#system_certs} )) && (( ${#git_certs} )); then
    export GIT_SSL_CAPATH="${git_certs[1]}"
    export MAMBA_SSL_VERIFY="$GIT_SSL_CAPATH/cacert.pem"
  fi
}
