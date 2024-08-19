#!/bin/sh

# initialize config
if [ ! -f "/root/.osmosisd/config/app.toml" ]; then
  echo "Writing initial config"
  mkdir -p /root/.osmosisd/config
  cp /etc/osmosis/app.toml /root/.osmosisd/config/app.toml
  echo '{"height":"0","round":0,"step":0}' > /root/.osmosisd/data/priv_validator_state.json
fi

exec /osmosisd start --log_format json --rpc.laddr tcp://0.0.0.0:26657 --x-crisis-skip-assert-invariants "$@"
