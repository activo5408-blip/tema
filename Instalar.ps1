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


  # Copia los iconos originales del tema Eleven.
  $localIcons = Join-Path $PSScriptRoot '@Resources\Icons'
  $iconRoot = Join-Path $skinRoot '@Resources\Icons'
  if (Test-Path $localIcons) {
    New-Item -ItemType Directory -Path $iconRoot -Force | Out-Null
    Copy-Item -Path (Join-Path $localIcons '*.svg') -Destination $iconRoot -Force

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
      $svgPath = Join-Path $iconRoot ($icon + '.svg')
      $pngPath = Join-Path $iconRoot ($icon + '.png')
      $svg = Get-Content -LiteralPath $svgPath -Raw
      $svg = $svg -replace '<\?xml[^>]*\?>', ''
      $svg = $svg -replace 'currentColor', '#DDE4EE'
      $htmlPath = Join-Path $iconRoot ($icon + '-render.html')
      $html = '<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;width:64px;height:64px;background:transparent;overflow:hidden}svg{width:64px;height:64px}</style></head><body>' + $svg + '</body></html>'
      Set-Content -LiteralPath $htmlPath -Value $html -Encoding UTF8
      $fileUrl = 'file:///' + ($htmlPath -replace '\\','/')
      & $edge --headless --disable-gpu --hide-scrollbars --default-background-color=00000000 --window-size=64,64 "--screenshot=$pngPath" $fileUrl 2>$null | Out-Null
      Remove-Item -LiteralPath $htmlPath -Force -ErrorAction SilentlyContinue
      if (-not (Test-Path $pngPath)) { throw "No se pudo convertir el icono $icon a PNG." }
    }
  } else {
    throw 'No se encontró @Resources\Icons en la carpeta extraída. Descarga y extrae el ZIP completo.'
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
