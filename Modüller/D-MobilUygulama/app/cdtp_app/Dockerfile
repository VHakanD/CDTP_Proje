# =============================================================================
# CDTP Robot Izleme - Docker derlemesi
#
#   dev   : Flutter + bagimliliklar + uretilen kod (testler bu asamada kosar)
#   build : Flutter web derlemesi
#   final : nginx ile web arayuzunu sunar (http://localhost:8080)
#
# Not: Web surumu ARAYUZ TESTI icindir. Kamera tarayicida calisir, BLE calismaz,
# raporlar bellekte tutulur. Asil hedef Android uygulamasidir.
# =============================================================================

FROM ghcr.io/cirruslabs/flutter:stable AS dev
WORKDIR /app

# Once sadece bagimlilik dosyalari: kod degisince pub get tekrar calismasin.
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
# Eksik platform klasorlerini (web/) olusturur; var olan dosyalara dokunmaz.
RUN flutter create . --platforms=web --project-name cdtp_robot_app --org edu.ytu.cdtp \
 && flutter pub get \
 && dart run build_runner build --delete-conflicting-outputs

FROM dev AS build
RUN flutter build web --release

FROM nginx:1.27-alpine
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
