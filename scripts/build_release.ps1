<#
.SYNOPSIS
    Build rilis produksi TaskFlow mobile (APK / App Bundle) dengan
    API_BASE_URL wajib disertakan lewat --dart-define.

.DESCRIPTION
    AppConfig.baseUrl akan melempar StateError saat start jika build
    release dijalankan tanpa API_BASE_URL - skrip ini mencegah kamu sampai
    ke titik itu dengan memvalidasi parameter di awal, sebelum Gradle
    dijalankan (menghemat waktu build yang gagal di akhir).

.PARAMETER ApiBaseUrl
    Base URL API Gateway produksi, contoh: https://api.taskflow.app/api
    WAJIB https:// kecuali untuk smoke test ke alamat lokal/LAN.

.PARAMETER Target
    'apk' (default, untuk sideload/testing internal) atau
    'appbundle' (.aab, wajib untuk upload ke Play Store).

.EXAMPLE
    ./scripts/build_release.ps1 -ApiBaseUrl https://api.taskflow.app/api
    ./scripts/build_release.ps1 -ApiBaseUrl https://api.taskflow.app/api -Target appbundle
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ApiBaseUrl,

    [ValidateSet('apk', 'appbundle')]
    [string]$Target = 'apk'
)

$ErrorActionPreference = 'Stop'

if ($ApiBaseUrl -notmatch '^https?://') {
    throw "ApiBaseUrl harus diawali http:// atau https:// - nilai diterima: '$ApiBaseUrl'"
}
if ($ApiBaseUrl -notmatch '^https://' -and $ApiBaseUrl -notmatch '(localhost|127\.0\.0\.1|10\.0\.2\.2|192\.168\.|10\.)') {
    Write-Warning "ApiBaseUrl pakai http:// (bukan https://) ke host yang bukan alamat lokal. Android API 28+ memblokir cleartext traffic ke domain publik secara default - build ini kemungkinan gagal connect di device asli."
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    if (-not (Test-Path (Join-Path $repoRoot 'android/key.properties'))) {
        throw "android/key.properties tidak ditemukan - release akan ter-signing dengan debug key (tidak bisa di-upload ke Play Store). Lihat panduan signing di README.md."
    }

    Write-Host "Building $Target dengan API_BASE_URL=$ApiBaseUrl ..." -ForegroundColor Cyan

    if ($Target -eq 'apk') {
        flutter build apk --release --dart-define=API_BASE_URL=$ApiBaseUrl
    } else {
        flutter build appbundle --release --dart-define=API_BASE_URL=$ApiBaseUrl
    }

    if ($LASTEXITCODE -ne 0) {
        throw "flutter build gagal (exit code $LASTEXITCODE)"
    }

    Write-Host "Build selesai." -ForegroundColor Green
    if ($Target -eq 'apk') {
        Write-Host "  build/app/outputs/flutter-apk/app-release.apk"
    } else {
        Write-Host "  build/app/outputs/bundle/release/app-release.aab"
    }
} finally {
    Pop-Location
}
