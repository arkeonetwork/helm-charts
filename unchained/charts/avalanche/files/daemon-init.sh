#!/bin/bash

set -e

apt update && apt install -y curl jq

start() {
  /avalanchego/build/avalanchego \
    --data-dir /data \
    --http-host 0.0.0.0 \
    --http-allowed-hosts "*" \
    --staking-ephemeral-cert-enabled=true \
    --chain-config-dir=/configs/chains &
  PID="$!"
}

stop() {
  echo "Catching signal and sending to PID: $PID" && kill $PID
  while $(kill -0 $PID 2>/dev/null); do sleep 1; done
}

trap 'stop' TERM INT
start
wait $PID