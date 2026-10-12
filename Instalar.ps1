$ErrorActionPreference = 'Stop'
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

  # Primero usa el INI que viene dentro del ZIP; así no depende de raw.githubusercontent.com.
  $localIni = Join-Path $PSScriptRoot 'DotCom.ini'
  if (Test-Path $localIni) {
    Copy-Item -LiteralPath $localIni -Destination $iniPath -Force
  } else {
    # Respaldo para cuando se ejecuta solo el instalador.
    $repoRaw = 'https://raw.githubusercontent.com/activo5408-blip/tema/main/DotCom.ini'
    Invoke-WebRequest -Uri $repoRaw -OutFile $iniPath -UseBasicParsing
  }

  if ($rainmeter) {
    Start-Process -FilePath $rainmeter -ArgumentList '!RefreshApp' -Wait
    Start-Sleep -Seconds 2
    Start-Process -FilePath $rainmeter -ArgumentList '!DeactivateConfig "DotCom" "DotCom.ini"' -Wait
    Start-Sleep -Milliseconds 500
    Start-Process -FilePath $rainmeter -ArgumentList '!ActivateConfig "DotCom" "DotCom.ini"' -Wait
    Write-Host ''
    Write-Host 'DotCom instalado y cargado correctamente.' -ForegroundColor Green
  } else {
    Write-Host ''
    Write-Host 'DotCom se copió, pero Rainmeter no está instalado o no se encontró.' -ForegroundColor Yellow
    Write-Host 'Instala Rainmeter desde https://www.rainmeter.net/ y vuelve a ejecutar Instalar.bat.'
  }
  Write-Host "Archivo instalado en: $iniPath"
} catch {
  Write-Host ''
  Write-Host 'No se pudo completar la instalación.' -ForegroundColor Red
  Write-Host $_.Exception.Message
  Write-Host 'Asegúrate de extraer el ZIP completo y ejecutar Instalar.bat desde esa carpeta.'
}
Write-Host ''
Read-Host 'Pulsa Enter para cerrar'
