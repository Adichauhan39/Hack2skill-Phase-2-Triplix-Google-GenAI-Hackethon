# Downloads required font files into assets/fonts
# Run from repo root or from flutter_travel_app directory

$ErrorActionPreference = 'Stop'

function Ensure-Folder($path){
  if(-not (Test-Path $path)){ New-Item -ItemType Directory -Path $path | Out-Null }
}

$fontDir = Join-Path $PSScriptRoot 'assets/fonts'
Ensure-Folder $fontDir

$fonts = @(
  @{ Url = 'https://github.com/google/fonts/raw/main/ofl/notosans/NotoSans-Regular.ttf'; Name='NotoSans-Regular.ttf' }
  @{ Url = 'https://github.com/google/fonts/raw/main/ofl/notosans/NotoSans-Medium.ttf'; Name='NotoSans-Medium.ttf' }
  @{ Url = 'https://github.com/google/fonts/raw/main/ofl/notosans/NotoSans-SemiBold.ttf'; Name='NotoSans-SemiBold.ttf' }
  @{ Url = 'https://github.com/google/fonts/raw/main/ofl/notosans/NotoSans-Bold.ttf'; Name='NotoSans-Bold.ttf' }
  @{ Url = 'https://github.com/google/fonts/raw/main/ofl/notosansmono/NotoSansMono-Regular.ttf'; Name='NotoSansMono-Regular.ttf' }
  @{ Url = 'https://github.com/google/fonts/raw/main/ofl/notosansmono/NotoSansMono-Bold.ttf'; Name='NotoSansMono-Bold.ttf' }
  @{ Url = 'https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Regular.ttf'; Name='Roboto-Regular.ttf' }
  @{ Url = 'https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Bold.ttf'; Name='Roboto-Bold.ttf' }
)

Write-Host "Downloading font files to $fontDir" -ForegroundColor Cyan

foreach($f in $fonts){
  $dest = Join-Path $fontDir $f.Name
  if(Test-Path $dest){
    Write-Host "Skipped (exists): $($f.Name)" -ForegroundColor Yellow
    continue
  }
  Write-Host "Downloading: $($f.Name)" -ForegroundColor Green
  Invoke-WebRequest -Uri $f.Url -OutFile $dest
}

Write-Host "Done. Now run: flutter pub get" -ForegroundColor Cyan
