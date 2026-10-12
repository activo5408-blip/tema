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

    # Generar PNG localmente con System.Drawing. No depende de Edge ni de Internet.
    Write-Host 'Creando iconos PNG con Windows...' -ForegroundColor Cyan
    Add-Type -AssemblyName System.Drawing
    foreach ($icon in @('CPU','RAM','Network','Disk')) {
      Write-Host "Preparando icono $icon..." -ForegroundColor Cyan
      $pngPath = Join-Path $iconRoot ($icon + '.png')
      $bmp = New-Object System.Drawing.Bitmap(64,64)
      $g = [System.Drawing.Graphics]::FromImage($bmp)
      $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
      $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(221,228,238),3)
      $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
      $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
      $g.Clear([System.Drawing.Color]::Transparent)
      switch ($icon) {
        'CPU' {
          $g.DrawRectangle($pen,17,17,30,30)
          $g.DrawRectangle($pen,24,24,16,16)
          foreach ($p in @(22,32,42)) {
            $g.DrawLine($pen,$p,9,$p,17); $g.DrawLine($pen,$p,47,$p,55)
            $g.DrawLine($pen,9,$p,17,$p); $g.DrawLine($pen,47,$p,55,$p)
          }
        }
        'RAM' {
          $g.DrawRectangle($pen,8,19,48,26)
          foreach ($x in @(14,23,32,41,50)) { $g.DrawRectangle($pen,$x,25,5,9); $g.DrawLine($pen,$x+2,45,$x+2,53) }
        }
        'Network' {
          $g.DrawLine($pen,19,20,44,19); $g.DrawLine($pen,19,20,31,44); $g.DrawLine($pen,44,19,31,44)
          $g.DrawEllipse($pen,11,12,16,16); $g.DrawEllipse($pen,36,11,16,16); $g.DrawEllipse($pen,23,37,16,16)
        }
        'Disk' {
          $g.DrawEllipse($pen,11,12,42,14); $g.DrawLine($pen,11,19,11,45); $g.DrawLine($pen,53,19,53,45)
          $g.DrawArc($pen,11,38,42,14,0,180); $g.DrawArc($pen,11,25,42,14,0,180)
        }
      }
      $bmp.Save($pngPath,[System.Drawing.Imaging.ImageFormat]::Png)
      $pen.Dispose(); $g.Dispose(); $bmp.Dispose()
      if (-not (Test-Path $pngPath) -or (Get-Item $pngPath).Length -eq 0) { throw "No se pudo crear el PNG del icono $icon." }
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
