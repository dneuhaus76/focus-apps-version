$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

function Update-WingetPackageList {
    param(
        [string]$DBFilePath = "$PSScriptRoot\winget-db"
    )

    if (!(Test-Path $DBFilePath)) {
        $null = New-Item -ItemType Directory -Path $DBFilePath -Force
    }

    $null = winget source update --disable-interactivity

    if (-not (Get-Module -ListAvailable Microsoft.WinGet.Client)) {
        Install-Module Microsoft.WinGet.Client -Scope CurrentUser -Force -AllowClobber
    }

    Import-Module Microsoft.WinGet.Client -Force

    $tmp = Find-WinGetPackage -Query "" -Source "winget"
    $allWingetPackages = $tmp | Select-Object Name, Id, Version, Source | Sort-Object Name, version -Descending
    $allWingetPackages | Export-Csv -Delimiter "`t" -NoTypeInformation -Path "$DBFilePath\$("AllWingetPackages" + ".csv")"
}

Update-WingetPackageList
