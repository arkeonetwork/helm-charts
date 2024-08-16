#!/bin/sh

# initialize config
if [ ! -f "/root/.osmosisd/config/app.toml" ]; then
  mkdir -p /root/.osmosisd/config
  cp /etc/osmosis/app.toml /root/.osmosisd/config/app.toml
fi

exec /osmosisd start --log_format json --rpc.laddr tcp://0.0.0.0:26657 --x-crisis-skip-assert-invariants "$@"
