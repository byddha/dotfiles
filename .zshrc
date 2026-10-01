# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Plugin manager
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Powerlevel10k theme
zinit ice depth=1; zinit light romkatv/powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Plugins
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-syntax-highlighting
zinit light Aloxaf/fzf-tab
zinit light jeffreytse/zsh-vi-mode

# Keybinding
bindkey '^k' history-search-backward
bindkey '^j' history-search-forward

# Completions
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no

# Aliases
alias ls='eza --color=always --group-directories-first --icons=auto'
alias lst='eza --color=always --group-directories-first --icons=auto --tree'
alias lst2='eza --color=always --group-directories-first --icons=auto --tree --level=2'
alias lg=='lazygit'
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
function mpvhdr() {
    ENABLE_HDR_WSI=1 mpv --vo=gpu-next --target-colorspace-hint --gpu-api=vulkan --gpu-context=waylandvk "$@"
}
function ludusavi() {
    flatpak run --command=ludusavi com.github.mtkennerly.ludusavi "$@"
}

# Environment variables
## Editor
[[ -n $SSH_CONNECTION ]] && export EDITOR='vim' || export EDITOR='nvim'
export SYSTEMD_EDITOR=vim
export PATH="$PATH:$HOME/dotfiles/scripts"
## Rocm
export ROCM_PATH=/opt/rocm
export HIP_VISIBLE_DEVICES=0
## Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
##
. "$HOME/.local/bin/env"

# Integrations
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"

# History
HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
if [[ -s $NVM_DIR/nvm.sh ]]; then
  # --no-use skips nvm's own `nvm use default`, which spends ~100ms resolving the alias in shell code.
  # The same PATH/NVM_BIN/NVM_INC result is set here; aliases not handled below
  # (lts/*, custom names, no default) still go through nvm.
  source "$NVM_DIR/nvm.sh" --no-use
  () {
    setopt localoptions extendedglob
    # A nested shell inherits the version in use, as nvm itself keeps it
    local bin=${path[(r)$NVM_DIR/versions/node/*/bin]} def
    if [[ -z $bin ]]; then
      [[ -r $NVM_DIR/alias/default ]] && def=$(<$NVM_DIR/alias/default)
      local -a v
      case $def in
        node|stable) v=($NVM_DIR/versions/node/v*(N/n)) ;;
        (v|)<->(.<->)#) v=($NVM_DIR/versions/node/v${def#v}(|.*)(N/n)) ;;
      esac
      (( $#v )) || { nvm_auto use; return }
      bin=$v[-1]/bin
    fi
    path=($bin ${path:#$bin})
    export NVM_BIN=$bin NVM_INC=${bin%/bin}/include/node
  }
fi

# `ng completion script` boots node (~75ms), so its output is cached as an autoloaded _ng
# and regenerated only when ng is newer than the cache
() {
  local dir=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions ng=${commands[ng]}
  if [[ -n $ng ]]; then
    [[ -d $dir ]] || mkdir -p $dir
    [[ $dir/_ng -nt $ng ]] || { ng completion script >| $dir/_ng.tmp && mv -f $dir/_ng.tmp $dir/_ng }
  elif [[ -e $dir/_ng ]]; then
    rm -f $dir/_ng
  fi
  fpath=($dir $fpath)
}

autoload -Uz compinit && compinit
# Sourced after compinit: before it, this file runs its own compinit and the completion system starts twice
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
# _bun calls compdef, and runs compinit itself if it isn't loaded yet
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/dotfiles/.p10k.zsh.
[[ ! -f ~/dotfiles/.p10k.zsh ]] || source ~/dotfiles/.p10k.zsh
