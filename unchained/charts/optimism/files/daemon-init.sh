#!/bin/sh

set -e

apk add bash curl jq aria2 tar zstd openssl

DATA_DIR=/data
CHAINDATA_DIR=$DATA_DIR/geth/chaindata
dirName="mainnet-bedrock.tar.zst"
EXPECTED_CHECKSUM="c17067b7bc39a6daa14f71d448c6fa0477834c3e68a25e96f26fe849c12a09bffe510e96f7eacdef19e93e3167d15250f807d252dd6f6f9053d0e4457c73d5fb mainnet-bedrock.tar.zst"

#if [ -n "$SNAPSHOT" ] && [ ! -d "$CHAINDATA_DIR" ]; then
#  wget -c $SNAPSHOT -O - | tar --zstd -xvf - -C $DATA_DIR
#fi

if [ -n "$SNAPSHOT" ]; then
    echo "Restoring from snapshot"

    # Download and extract the snapshot
    if [[ ! -f $dirName ]]; then
    aria2c -c -s4 -x4 -k1024M $SNAPSHOT
    fi

    CHECKSUM=$(sha512sum mainnet-bedrock.tar.zst)

    while [[ $CHECKSUM -ne $EXPECTED_CHECKSUM ]]; do
      echo "rerunning due to checksum mismatch"
      aria2c -c -s4 -x4 -k1024M $SNAPSHOT;
    done

    zstd -cd $DATA_DIR | tar xf -
fi  


start() {
  geth \
    --networkid 10 \
    --syncmode full \
    --datadir $DATA_DIR \
    --authrpc.jwtsecret /jwt.hex \
    --authrpc.port 8551 \
    --http \
    --http.addr 0.0.0.0 \
    --http.port 8545 \
    --http.api eth,net,web3,debug,txpool,engine \
    --http.vhosts "*" \
    --http.corsdomain "*" \
    --ws \
    --ws.addr 0.0.0.0 \
    --ws.port 8546 \
    --ws.api eth,net,web3,debug,txpool,engine \
    --ws.origins "*" \
    --rollup.disabletxpoolgossip=true \
    --rollup.sequencerhttp https://mainnet-sequencer.optimism.io \
    --txlookuplimit 0 \
    --cache 4096 \
    --maxpeers 0 \
    --nodiscover &
  PID="$!"
}

stop() {
  echo "Catching signal and sending to PID: $PID" && kill $PID
  while $(kill -0 $PID 2>/dev/null); do sleep 1; done
}

trap 'stop' TERM INT
start
wait $PID