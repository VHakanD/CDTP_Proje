# =============================================================================
# cdtp_monitor - Docker ile gelistirme
#
#   dev  : Flutter web-server + canli yenileme (docker/dev-entrypoint.sh)
#   test : flutter analyze + flutter test
#
# Not: Web onizlemesi arayuz ve akis icindir; kamera yerine simulator sahnesi
# kullanilir. Gercek kamera ve video kaydi Android cihazda calisir.
# =============================================================================
FROM debian:bookworm-slim AS dev
ARG FLUTTER_VERSION=3.47.7
RUN apt-get update  && apt-get install -y --no-install-recommends curl git unzip xz-utils ca-certificates  && rm -rf /var/lib/apt/lists/*
# Yerel SDK ile ayni surum (pubspec.lock bu surumle uretildi)
RUN git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH"
RUN flutter config --no-analytics --enable-web  && flutter precache --web --no-android --no-ios
WORKDIR /app

# Once yalniz bagimlilik dosyalari: kod degisince pub get tekrar calismasin.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
EXPOSE 8080
CMD ["sh", "docker/dev-entrypoint.sh"]

FROM dev AS test
CMD ["sh", "-c", "flutter analyze && flutter test"]
