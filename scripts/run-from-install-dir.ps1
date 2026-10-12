# release 빌드한 flutty_dock.exe를 설치 폴더(C:\Program Files\Flutty Dock)를 작업 디렉터리로 삼아 실행한다.
# 설치본을 덮어쓰지 않는다. 설치 폴더에서 실행할 때만 나는 문제(쓰기 권한, 코드 페이지 등)를 재현하는 용도.
#
# 사용: powershell -ExecutionPolicy Bypass -File scripts\run-from-install-dir.ps1 [-SkipBuild]
param(
  [switch]$SkipBuild,
  [string]$InstallDir = (Join-Path $env:ProgramFiles 'Flutty Dock')
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$exe = Join-Path $repo 'build\windows\x64\runner\Release\flutty_dock.exe'

if (-not (Test-Path $InstallDir)) { throw "설치 폴더가 없습니다: $InstallDir" }

if (-not $SkipBuild) {
  Push-Location $repo
  try {
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw 'flutter build windows 실패' }
  } finally { Pop-Location }
}

if (-not (Test-Path $exe)) { throw "빌드 결과가 없습니다: $exe" }

Write-Host "실행: $exe"
Write-Host "작업 디렉터리: $InstallDir"
Start-Process -FilePath $exe -WorkingDirectory $InstallDir
