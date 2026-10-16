# ESP32-S3 robot + eldiven simulatoru (AOT derlenmis, kucuk imaj)
FROM dart:3.13.5 AS build
WORKDIR /sim
COPY pubspec.yaml pubspec.lock* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/esp32_sim.dart -o /sim/esp32_sim

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /sim/esp32_sim /app/esp32_sim
EXPOSE 8765
CMD ["/app/esp32_sim", "--port", "8765"]
