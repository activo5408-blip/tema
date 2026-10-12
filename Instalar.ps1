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


  Write-Host 'Copiando archivos del tema DotCom...' -ForegroundColor Cyan
  # Copia los iconos originales del tema Eleven.
  $localIcons = Join-Path $PSScriptRoot '@Resources\Icons'
  $iconRoot = Join-Path $skinRoot '@Resources\Icons'
  if (Test-Path $localIcons) {
    New-Item -ItemType Directory -Path $iconRoot -Force | Out-Null
    Copy-Item -Path (Join-Path $localIcons '*.svg') -Destination $iconRoot -Force

    Write-Host 'Los SVG están copiados. Convirtiendo iconos a PNG con Edge...' -ForegroundColor Cyan
    # Rainmeter no lee SVG directamente: los convertimos a PNG con Microsoft Edge,
    # que normalmente ya viene instalado en Windows.
    $edgeCandidates = @(
      "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
      "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
      "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe"
    )
    $edge = $edgeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $edge) { throw 'No se encontró Microsoft Edge para preparar los iconos. Instala/actualiza Edge y vuelve a ejecutar el instalador.' }

    foreach ($icon in @('CPU','RAM','Network','Disk')) {
      Write-Host "Preparando icono $icon..." -ForegroundColor Cyan
      $svgPath = Join-Path $iconRoot ($icon + '.svg')
      $pngPath = Join-Path $iconRoot ($icon + '.png')
      if (-not (Test-Path $svgPath)) { throw "Falta el archivo $icon.svg en $localIcons" }

      # Abrir el SVG directamente en Edge headless evita el HTML intermedio,
      # que en algunas versiones de Edge deja la ventana negra o se queda esperando.
      $fileUrl = ([System.Uri]::new($svgPath)).AbsoluteUri
      $profileDir = Join-Path $env:TEMP ('DotCom-Edge-' + $icon)
      $edgeArgs = @(
        '--headless',
        '--disable-gpu',
        '--no-first-run',
        '--no-default-browser-check',
        "--user-data-dir=$profileDir",
        '--window-size=64,64',
        "--screenshot=$pngPath",
        $fileUrl
      )
      $proc = Start-Process -FilePath $edge -ArgumentList $edgeArgs -PassThru -WindowStyle Hidden
      if (-not $proc.WaitForExit(15000)) {
        try { $proc.Kill() } catch {}
        throw "Edge tardó demasiado preparando el icono $icon. Cierra Edge y vuelve a ejecutar el instalador."
      }
      Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
      if (-not (Test-Path $pngPath) -or (Get-Item -LiteralPath $pngPath).Length -eq 0) {
        throw "Edge no pudo generar el PNG de $icon. El instalador se detuvo en ese icono."
      }
    }
  } else {
    throw 'No se encontró @Resources\Icons en la carpeta extraída. Descarga y extrae el ZIP completo.'
  }

  Write-Host 'Iconos preparados. Terminando instalación de DotCom...' -ForegroundColor Cyan
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
