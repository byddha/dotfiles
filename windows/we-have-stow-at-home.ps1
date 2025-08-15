$DotfilesDir = "$env:USERPROFILE\dotfiles"
$WindowsDir = "$env:USERPROFILE\dotfiles\windows"

$Links = @{
    "$WindowsDir\wezterm" = "$env:USERPROFILE\.config\wezterm"
    "$WindowsDir\Microsoft.PowerShell_profile.ps1" = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    "$WindowsDir\.oh-my-posh.json" = "$env:USERPROFILE\.oh-my-posh.json"
    "$DotfilesDir\.config\nvim" = "$env:LOCALAPPDATA\nvim"
}

foreach ($src in $Links.Keys) {
    $dst = $Links[$src]
    if (Test-Path $dst) {
        Remove-Item $dst -Recurse -Force
    }
    New-Item -ItemType SymbolicLink -Path $dst -Target $src
    Write-Output "Symlinked $dst to $src"
}
