$ErrorActionPreference = 'Stop'
$repoRaw = 'https://raw.githubusercontent.com/activo5408-blip/tema/main/DotCom.ini?cache=' + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$rainmeterDirs = @(
  "$env:APPDATA\Rainmeter\Rainmeter.exe",
  "$env:ProgramFiles\Rainmeter\Rainmeter.exe",
  "${env:ProgramFiles(x86)}\Rainmeter\Rainmeter.exe"
)
$rainmeter = $rainmeterDirs | Where-Object { Test-Path $_ } | Select-Object -First 1

try {
  $documents = [Environment]::GetFolderPath('MyDocuments')
  $skinRoot = Join-Path $documents 'Rainmeter\Skins\DotCom'
  New-Item -ItemType Directory -Path $skinRoot -Force | Out-Null
  $iniPath = Join-Path $skinRoot 'DotCom.ini'
  Invoke-WebRequest -Uri $repoRaw -OutFile $iniPath -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache'; 'Pragma' = 'no-cache' }

  if ($rainmeter) {
    Start-Process -FilePath $rainmeter -ArgumentList '!RefreshApp' -Wait
    Start-Sleep -Seconds 2
    Start-Process -FilePath $rainmeter -ArgumentList '!DeactivateConfig "DotCom" "DotCom.ini"' -Wait
    Start-Sleep -Milliseconds 500
    Start-Process -FilePath $rainmeter -ArgumentList '!ActivateConfig "DotCom" "DotCom.ini"' -Wait
    Write-Host ''
    Write-Host 'Instalado y cargado correctamente.' -ForegroundColor Green
  } else {
    Write-Host ''
    Write-Host 'El tema se instaló, pero Rainmeter no está instalado o no se encontró.' -ForegroundColor Yellow
    Write-Host 'Instala Rainmeter desde https://www.rainmeter.net/ y vuelve a ejecutar Instalar.bat.'
  }
  Write-Host "Archivo instalado en: $iniPath"
} catch {
  Write-Host ''
  Write-Host 'No se pudo completar la instalación.' -ForegroundColor Red
  Write-Host $_.Exception.Message
  Write-Host 'Comprueba tu conexión a Internet e inténtalo otra vez.'
}
Write-Host ''
Read-Host 'Pulsa Enter para cerrar'
