function Update-WingetPackageList {

    Param
    (
        [Parameter(Mandatory = $false)][string]$DBFilePath = "$($PSScriptRoot)\winget-db"
    )
    
    $ErrorActionPreference = 'Stop'
    
    # Winget Location & Update
    $appInstaller = Get-AppPackage *Microsoft.DesktopAppInstaller*
    if ($null -eq $appInstaller) { throw "WinGet (AppInstaller) ist nicht installiert!" }
    Set-Location $appInstaller.InstallLocation

    $ver = & .\winget.exe --version --disable-interactivity
    Write-Host "winget version $ver before update"
    
    $null = & .\winget.exe source update -n winget --disable-interactivity
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Winget source update erfolgreich." -ForegroundColor Green
    }
  
    if (!(Test-Path $DBFilePath)) { $null = New-Item $DBFilePath -Force -ItemType Directory }

    # --- AUTOMATISIERUNG DER ABHÄNGIGKEITEN ---
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # NuGet Provider
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Write-Host "Installiere NuGet-Provider..." -ForegroundColor Cyan
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ForceBootstrap -Scope Process
    }

    # Gallery als vertrauenswürdig markieren (WICHTIG für Pipelines)
    if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }

    # WinGet-Modul
    if (-not (Get-Module -ListAvailable -Name Microsoft.WinGet.Client)) {
        Write-Host "Installiere Modul 'Microsoft.WinGet.Client'..." -ForegroundColor Cyan
        Install-Module -Name Microsoft.WinGet.Client -Scope Process -Force -AllowClobber
    }

    Import-Module Microsoft.WinGet.Client -Force

    # --- DATEN EXPORT ---
    Write-Host "Exportiere alle Pakete (dies kann dauern)..."
    # Find-WinGetPackage ohne Query gibt alle verfügbaren Pakete zurück
    $allWingetPackages = Find-WinGetPackage -Source "winget"
    
    $allWingetPackages | Select-Object Name, Id, Source, Version | 
        Sort-Object Name, Version -Descending | 
        Export-Csv -Delimiter "`t" -NoTypeInformation -Path "$DBFilePath\AllWingetPackages.csv" -Encoding UTF8

    Write-Host "File exported: $DBFilePath\AllWingetPackages.csv" -ForegroundColor Green

}

#main
Update-WingetPackageList
