$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Update-WingetPackageList {
    param(
        [string]$DBFilePath = "$PSScriptRoot\winget-db"
    )

    if (!(Test-Path $DBFilePath)) {
        $null = New-Item -ItemType Directory -Path $DBFilePath -Force
    }

    $null = winget source update --disable-interactivity --accept-source-agreements

    if (-not (Get-Module -ListAvailable Microsoft.WinGet.Client)) {
        Install-Module Microsoft.WinGet.Client -Scope CurrentUser -Force -AllowClobber
    }

    Import-Module Microsoft.WinGet.Client -Force

    Find-WinGetPackage -Source winget |
        Select Name, Id, Source, Version |
        Sort Name, Version -Descending |
        Export-Csv "$DBFilePath\AllWingetPackages.csv" -Delimiter "`t" -NoTypeInformation
}

Update-WingetPackageList
