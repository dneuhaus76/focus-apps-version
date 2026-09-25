$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

function Update-WingetPackageList {
    param(
        [string]$DBFilePath = "$PSScriptRoot\winget-db",
        [string]$Query = "",
        [string]$Source = "winget"
    )

    if (!(Test-Path $DBFilePath)) {
        $null = New-Item -ItemType Directory -Path $DBFilePath -Force
    }

    if (-not (Get-PackageProvider "NuGet")) {
        $msg = Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.201" -Scope AllUsers -Force
        Write-Output $msg
        $null = Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.201" -Scope CurrentUser -Force
    }

    Start-Process powershell.exe -ArgumentList('-NoProfile -Command "winget install "Microsoft.AppInstaller" --disable-interactivity --force"') -Wait -WindowStyle Hidden
    $msg = winget source update --disable-interactivity
    Write-Output $msg

    if (-not (Get-Module -ListAvailable Microsoft.WinGet.Client)) {
        $msg = Install-Module Microsoft.WinGet.Client -Scope CurrentUser -AllowClobber -Force
        Write-Output $msg
    }

    Import-Module Microsoft.WinGet.Client -Force
    
    $allWingetPackages = @()
    $allWingetPackages = @(Find-WinGetPackage -Query "$($Query)" -Source "$($Source)" | Select-Object Name, Id, Version, Source -First 1)
    if ($allWingetPackages.Count -eq 0) {
        $null = Repair-WinGetPackageManager -Latest -Force
    } else {
        Write-Error "[!] A Test-Package could not be found, so we quit run"
        Exit 1
    }
    
    Write-Output "wait while collecting packages..."
    $allWingetPackages = @(Find-WinGetPackage -Query "$($Query)" -Source "$($Source)" | Select-Object Name, Id, Version, Source | Sort-Object Name, Version)
    if ($allWingetPackages.count -gt 0) {
        $allWingetPackages | Export-Csv -Delimiter "`t" -NoTypeInformation -Path "$DBFilePath\$("AllWingetPackages" + ".csv")" -Encoding utf8 -Force
        ConvertTo-Json -Depth 5 -InputObject $($allWingetPackages) | Out-File -FilePath $("$DBFilePath\AllWingetPackages.json") -Encoding utf8 -Force
    }
    Write-Output 'Output in: $("$DBFilePath\AllWingetPackages.json")'
}

Update-WingetPackageList
