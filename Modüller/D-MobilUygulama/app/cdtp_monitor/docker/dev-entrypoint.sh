#!/bin/sh
# Flutter web-server'i baslatir ve lib/ altindaki degisikliklerde hot reload yapar.
# Windows bind mount'larinda inotify olaylari gelmedigi icin 1 s'de bir yoklanir.
set -eu

PID_FILE=/tmp/flutter.pid
STAMP=/tmp/last-reload
rm -f "$PID_FILE"

flutter run -d web-server \
  --web-hostname 0.0.0.0 --web-port 8080 \
  --pid-file "$PID_FILE" &
RUN_PID=$!

while [ ! -f "$PID_FILE" ]; do
  kill -0 "$RUN_PID" 2>/dev/null || exit 1
  sleep 1
done
touch "$STAMP"
echo "[canli] http://localhost:8080  ·  ornek: http://localhost:8080/?demo=B#/camera"

while kill -0 "$RUN_PID" 2>/dev/null; do
  sleep 1
  if [ -n "$(find lib -name '*.dart' -newer "$STAMP" 2>/dev/null | head -n 1)" ]; then
    touch "$STAMP"
    echo "[canli] degisiklik algilandi -> hot reload"
    kill -USR1 "$(cat "$PID_FILE")" || true   # USR2 = hot restart
  fi
done
wait "$RUN_PID"
