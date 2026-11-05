#!/usr/bin/env bash
# Runs the rules tests and the worker's emulator tests against real Firestore
# behaviour.
#
# Starts the emulator's jar directly: firebase-tools refuses Java before 21, while
# the jar itself runs on the Java 17 that the Android build uses. If the jar is
# missing, `firebase setup:emulators:firestore` downloads it.
set -euo pipefail
cd "$(dirname "$0")/.."

PORT=18080
JAR=$(ls ~/.cache/firebase/emulators/cloud-firestore-emulator-*.jar 2>/dev/null | sort -V | tail -1 || true)
if [ -z "$JAR" ]; then
  echo "No emulator found. Run: firebase setup:emulators:firestore" >&2
  exit 1
fi

java -jar "$JAR" --host 127.0.0.1 --port "$PORT" >/dev/null 2>&1 &
EMULATOR=$!
trap 'kill "$EMULATOR" 2>/dev/null || true' EXIT

for _ in $(seq 1 30); do
  curl -s -o /dev/null "http://127.0.0.1:$PORT/" && break
  sleep 1
done

FIRESTORE_EMULATOR_HOST="127.0.0.1:$PORT" \
  node --test rules_test/*.test.js push_worker/emulator/*.test.js
