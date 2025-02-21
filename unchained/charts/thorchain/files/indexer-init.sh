#!/bin/sh

set -e

start_service() {
  if [[ -f /blockstore/genesis.json ]]; then
    wget -O /blockstore/genesis.json https://storage.googleapis.com/public-snapshots-ninerealms/genesis/17562000.json
  fi

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
