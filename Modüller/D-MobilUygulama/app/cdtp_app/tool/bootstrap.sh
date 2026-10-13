#!/usr/bin/env sh
# Yeni bir bilgisayarda projeyi ilk kez hazirlar (Linux / macOS / Git Bash).
# Kullanim:  sh tool/bootstrap.sh
#
# 1) Eksik platform klasorlerini (android/, web/) olusturur; var olan dosyalara dokunmaz.
# 2) Paketleri indirir.
# 3) drift veritabani kodunu uretir (lib/data/db/app_database.g.dart).
set -e
cd "$(dirname "$0")/.."

flutter create . --platforms=android,web --project-name cdtp_robot_app --org edu.ytu.cdtp
flutter pub get
dart run build_runner build --delete-conflicting-outputs

echo ""
echo "Hazir. Kontrol:  flutter analyze && flutter test"
echo "Telefonda calistirma:  flutter run"
