# Copy pastes
- Setup
```bash
git clone https://github.com/byddha/dotfiles ~/dotfiles
cd ~/dotfiles
stow .
```

- Neovim in docker
```bash
docker run -w /root -it --rm alpine:edge sh -uelic '
  apk add git lazygit fzf curl neovim ripgrep alpine-sdk --update
  git clone https://github.com/byddha/dotfiles ~/dotfiles
  cp -r ~/dotfiles/.config/nvim ~/.config/nvim 
  cd ~/.config/nvim
  nvim
'
```

- Fresh arch hyprland install
```bash
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
sudo pacman -S - < pkglist.txt
paru -S - < pgklist-aur.txt
git clone https://github.com/byddha/dotfiles ~/dotfiles
cd ~/dotfiles
stow .
```
