#!/bin/sh

set -e

start_service() {
  #if [[ -f /blockstore/genesis.json ]]; then
  wget -O /blockstore/genesis.json https://rpc-v1.ninerealms.com/genesis
  #fi
  #rm -rf /blockstore/*

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
