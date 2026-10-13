# Robot simulatoru: bagimliliksiz Dart WebSocket sunucusu.
FROM dart:stable AS build
WORKDIR /app
COPY pubspec.yaml ./
RUN dart pub get
COPY bin ./bin
RUN dart compile exe bin/robot_simulator.dart -o /app/robot_simulator

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/robot_simulator /app/robot_simulator
ENV PORT=8765
EXPOSE 8765
CMD ["/app/robot_simulator"]
