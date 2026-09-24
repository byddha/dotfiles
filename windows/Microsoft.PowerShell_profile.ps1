# The prompt is compiled C# (windows\prompt) because a script prompt costs ~40 ms more per new tab.
# Loaded from bytes so the DLL can be rebuilt while tabs are open.
[void][Reflection.Assembly]::Load([IO.File]::ReadAllBytes("$HOME\dots\windows\prompt\out\DotsPrompt.dll"))
[DotsPrompt.Prompt]::SetInitialDirectory($PWD.ProviderPath)

function prompt {
    $ok = $?
    $last = Get-History -Count 1
    [DotsPrompt.Prompt]::Render($ok, $LASTEXITCODE, $(if ($last) { $last.Duration.TotalSeconds } else { 0 }),
        $PWD.ProviderPath, $PWD.Provider.Name -eq 'FileSystem', $HOME, $Host.UI.RawUI.WindowSize.Width, $env:VIRTUAL_ENV)
}

# zoxide's init costs ~60 ms, so it loads on first use; the prompt records visited dirs itself.
function Import-Zoxide {
    Remove-Item function:z, function:zi
    . ([ScriptBlock]::Create((zoxide init powershell --hook none | Out-String)))
}
function global:z { Import-Zoxide; z @args }
function global:zi { Import-Zoxide; zi @args }

function OnViModeChange {
    if ($args[0] -eq 'Command') {
        [Console]::Write("`e[1 q")
    } else {
        [Console]::Write("`e[5 q")
    }
}
Set-PSReadLineOption -EditMode Vi -ViModeIndicator Script -ViModeChangeHandler $Function:OnViModeChange -BellStyle Visual `
    -ContinuationPrompt "`e[38;5;76m$([char]0x276F)$([char]0x276F)`e[0m "

# Set-Alias would auto-load Microsoft.PowerShell.Utility at startup.
function lg { lazygit @args }

function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath $cwd
    }
    Remove-Item -Path $tmp
}

