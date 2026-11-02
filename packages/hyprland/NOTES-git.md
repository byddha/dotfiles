# Note istorice: Hyprland 0.56.2 pe main

Din 2026-11-02, PKGBUILD-ul folosește release-ul v0.57.0, commit
`0aa6745f705f2c4b0a5004eb019ef76e5bbdb426`, cu patch-ul local de captură
offscreen. Build-urile sunt pregătite pentru instalare ca `0.57.0-3.1`.
Fix-urile descrise mai jos sunt incluse în release; instrucțiunile de mai jos
documentează configurația și revenirea folosite înainte de acest update.

## De ce
În joc, după `workspace N` și înapoi, mouse-ul nu mai mișcă camera: cursorul e vizibil
și blocat (uneori pe al doilea monitor) până dai Escape → Escape în joc.

Cauza în 0.56.2: Hyprland ține lock-ul jocului (pointer-constraints) activ, dar pointer
focus-ul nu e pe joc, deci mișcarea relativă nu ajunge la joc. Ramura de lock din
`mouseMoveUnified` nu repune niciodată pointer focus-ul, iar `CPointerConstraint::activate()`
iese imediat dacă lock-ul e deja marcat activ.

Fix pe main (nelansat încă):
- https://github.com/hyprwm/Hyprland/pull/16311 (`f33e6a01`): lock-ul se activează
  odată cu pointer focus-ul; `rawWindowFocus` face mereu `unconstrainMouse()`
- https://github.com/hyprwm/Hyprland/pull/16455 (`90fb06e1`): repară regresia din #16311
  (slurp nu mergea cât timp pointer-ul era constrâns, inclusiv cu regula `confine_pointer`)

## Ce s-a schimbat
- `PKGBUILD` compilează commit-ul `19fb395d` de pe main, cu patch-ul
  `hyprland-capture-offscreen-windows.patch`
- dependență nouă `sdbus-cpp` (main o cere pentru rtkit); makedepends nou: `git`
- submodulele `hyprland-protocols` și `udis86` din clone locale; tracy e lăsat pe dinafară
- versiunea: `0.56.2.r247.g19fb395-1` (> 0.56.2 din repo, deci `pacman -Syu` nu o înlocuiește)
- `packages/.gitignore`: clonele git puse de makepkg lângă PKGBUILD
- `makepkg -si` a instalat în plus `hyprland-debug` și `hyprpm`

## Test
Workspace 6 gol, afișat pe al doilea monitor; jocul pe workspace 1 (DP-3), în gameplay.
`workspace 6`, apoi `workspace 1`, apoi mișcă mouse-ul. Repetă de mai multe ori
(pe 0.56.2 se strica doar uneori).

## Revenire la 0.56.2 (cu patch)
```
sudo pacman -Rns hyprland-debug hyprpm
sudo pacman -U ~/dotfiles/packages/hyprland/hyprland-0.56.2-4.1-x86_64.pkg.tar.zst
git -C ~/dotfiles checkout packages/hyprland/PKGBUILD packages/.gitignore
```
Commit-ul cu varianta 0.56.2: `dcc4793`. Nu șterge `hyprland-0.56.2-4.1-x86_64.pkg.tar.zst`
până nu e sigur că rămâi pe main.
