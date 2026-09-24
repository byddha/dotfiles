# Windows PowerShell 5.1 follows directory symlinks on Remove-Item -Recurse and would wipe dots.
#Requires -Version 7

$DotfilesDir = "$env:USERPROFILE\dots"
$WindowsDir = "$env:USERPROFILE\dots\windows"

$Links = @{
    "$WindowsDir\wezterm" = "$env:USERPROFILE\.config\wezterm"
    "$WindowsDir\noctty\config.ghostty" = "$env:LOCALAPPDATA\noctty\config.ghostty"
    "$WindowsDir\Microsoft.PowerShell_profile.ps1" = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    "$WindowsDir\.oh-my-posh.json" = "$env:USERPROFILE\.oh-my-posh.json"
    "$WindowsDir\vicinae" = "$env:LOCALAPPDATA\vicinae\config"
    "$DotfilesDir\.config\nvim" = "$env:LOCALAPPDATA\nvim"
}

function Remove-Destination($Path) {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if (-not $item) { return }
    if ($item.LinkType) {
        $item.Delete()
    }
    else {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
}

foreach ($src in $Links.Keys) {
    $dst = $Links[$src]
    Remove-Destination $dst
    New-Item -ItemType SymbolicLink -Path $dst -Target $src
    Write-Output "Symlinked $dst to $src"
}

# Scoop hardlinks a persisted file into the app dir, so both copies must point at dots.
$AltSnapIni = "$WindowsDir\altsnap\AltSnap.ini"
foreach ($dst in "$env:USERPROFILE\scoop\persist\altsnap\AltSnap.ini", "$env:USERPROFILE\scoop\apps\altsnap\current\AltSnap.ini") {
    Remove-Destination $dst
    New-Item -ItemType SymbolicLink -Path $dst -Target $AltSnapIni
    Write-Output "Symlinked $dst to $AltSnapIni"
}

# Scoop apps whose manifest has no shortcut; launchers only index the Start Menu.
$StartMenuDir = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Scoop Apps"
$Shortcuts = @{
    "noctty" = "$env:USERPROFILE\scoop\apps\noctty\current\noctty.exe"
}

$Shell = New-Object -ComObject WScript.Shell
New-Item -ItemType Directory -Path $StartMenuDir -Force | Out-Null
foreach ($name in $Shortcuts.Keys) {
    $lnk = $Shell.CreateShortcut("$StartMenuDir\$name.lnk")
    $lnk.TargetPath = $Shortcuts[$name]
    $lnk.WorkingDirectory = $env:USERPROFILE
    $lnk.Save()
    Write-Output "Shortcut $name -> $($Shortcuts[$name])"
}

# Logon tasks start right away; the Startup folder and Run keys are delayed by Windows.
$User = "$env:USERDOMAIN\$env:USERNAME"
$LogonTasks = @{
    "Vicinae" = "$env:USERPROFILE\scoop\apps\vicinae\current\bin\vicinae-server.exe"
    "AltSnap" = "$env:USERPROFILE\scoop\apps\altsnap\current\AltSnap.exe"
}

foreach ($name in $LogonTasks.Keys) {
    $exe = $LogonTasks[$name]
    $action = New-ScheduledTaskAction -Execute $exe -WorkingDirectory (Split-Path $exe)
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $User
    $principal = New-ScheduledTaskPrincipal -UserId $User -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
    Register-ScheduledTask -TaskPath '\dots\' -TaskName $name -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    Write-Output "Logon task $name -> $exe"
}