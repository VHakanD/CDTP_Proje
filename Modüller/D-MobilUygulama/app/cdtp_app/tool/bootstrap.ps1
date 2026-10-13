# Yeni bir bilgisayarda projeyi ilk kez hazirlar (Windows PowerShell).
# Kullanim:  .\tool\bootstrap.ps1
#
# 1) Eksik platform klasorlerini (android/, web/) olusturur. Var olan dosyalara
#    (lib/, AndroidManifest.xml, pubspec.yaml ...) DOKUNMAZ.
# 2) Paketleri indirir.
# 3) drift veritabani kodunu uretir (lib/data/db/app_database.g.dart).

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

flutter create . --platforms=android,web --project-name cdtp_robot_app --org edu.ytu.cdtp
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

dart run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ''
Write-Host 'Hazir. Kontrol:  flutter analyze ; flutter test'
Write-Host 'Telefonda calistirma:  flutter run'
