$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

function Update-WingetPackageList {
    param(
        [string]$DBFilePath = "$PSScriptRoot\winget-db",
        [string]$Query = "*",
        [string]$Source = "winget"
    )

    if (!(Test-Path $DBFilePath)) {
        $null = New-Item -ItemType Directory -Path $DBFilePath -Force
    }

    if (-not (Get-PackageProvider "NuGet")) {
        $null = Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.201" -Force
    }

    $null = winget source update --disable-interactivity

    if (-not (Get-Module -ListAvailable Microsoft.WinGet.Client)) {
        $null = Install-Module Microsoft.WinGet.Client -Scope AllUsers -AllowClobber -Force
        $null = Install-Module Microsoft.WinGet.Client -Scope CurrentUser -AllowClobber -Force
    }

    $null = Import-Module Microsoft.WinGet.Client -Force

    $allWingetPackages = @()
    $allWingetPackages = @(Find-WinGetPackage -Query "$($Query)" -Source "$($Source)" | Select-Object Name, Id, Version, Source -First 1)
    if ($allWingetPackages.Count -eq 0) {
        $null = Repair-WinGetPackageManager -Latest -AllUsers -Force
        $null = Repair-WinGetPackageManager -Latest -Force
    }

    $allWingetPackages = @(Find-WinGetPackage -Query "$($Query)" -Source "$($Source)" | Select-Object Name, Id, Version, Source -First 15 | Sort-Object Name, Version)
    if ($allWingetPackages.count -gt 0) {
        $allWingetPackages | Export-Csv -Delimiter "`t" -NoTypeInformation -Path "$DBFilePath\$("AllWingetPackages" + ".csv")" -Encoding utf8 -Force
        ConvertTo-Json -Depth 5 -InputObject $($allWingetPackages) | Out-File -FilePath $("$DBFilePath\AllWingetPackages.json") -Encoding utf8 -Force
    }
}

Update-WingetPackageList
