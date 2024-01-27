#!/bin/sh

set -e

MIDGARD_HASHES="https://storage.googleapis.com/public-snapshots-ninerealms/midgard-blockstore/mainnet/v2/hashes"

curl -s "$MIDGARD_HASHES"  >>/resources/hashes/thorchain

echo "done"

start_service() {
  ./midgard config.json &
  PID="$!"
}

stop_service() {
  echo "Catching signal and sending to PID: $PID"
  kill $PID
  while $(kill -0 $PID 2>/dev/null); do
    sleep 1
  done
}

trap 'stop_service' TERM INT

start_service
wait $PID