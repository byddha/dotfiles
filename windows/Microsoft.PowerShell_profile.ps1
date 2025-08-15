Import-Module PSReadLine

oh-my-posh init pwsh --config "$env:USERPROFILE/.oh-my-posh.json" | Invoke-Expression

function OnViModeChange {
    if ($args[0] -eq 'Command') {
        Write-Host -NoNewLine "`e[1 q"
    } else {
        Write-Host -NoNewLine "`e[5 q"
    }
}
Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler $Function:OnViModeChange
Set-PSReadLineOption -AddToHistoryHandler $Function:CommandAddedToHistoryHandler
Set-PSReadLineOption -BellStyle Visual

function Set-WezTermUserVar {
    param($Name, $Value)
    $encoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Value))
    $esc = [char]0x1b
    $bel = [char]0x07
    $seq = "${esc}]1337;SetUserVar=${Name}=${encoded}${bel}"
    Write-Host $seq -NoNewline
}

function Invoke-WithOsc1337 {
    param(
        [string]$Command,
        [Parameter(ValueFromRemainingArguments)]
        $Arguments
    )
    Set-WezTermUserVar "PROG" $Command
    try {
        $cmdPath = (Get-Command $Command -CommandType Application | Select-Object -ExpandProperty Source)
        & "$cmdPath" @Arguments
    }
    finally {
        Set-WezTermUserVar "PROG" ""
    }
}

function nvim { Invoke-WithOsc1337 nvim @args }
function lazygit { Invoke-WithOsc1337 lazygit @args }
