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

    $allWingetPackages = @(find-WingetPackage -Query "" -Source "winget" | Select-Object Name, Id, Version, Source | Sort-Object Name, Version)
    $allWingetPackages | Export-Csv -Delimiter "`t" -NoTypeInformation -Path "$DBFilePath\$("AllWingetPackages" + ".csv")" -Encoding utf8 -Force
    ConvertTo-Json -Depth 5 -InputObject $($allWingetPackages) | Out-File -FilePath $("$DBFilePath\AllWingetPackages.json") -Encoding utf8 -Force
}

Update-WingetPackageList
