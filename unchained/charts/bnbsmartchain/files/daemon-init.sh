#!/bin/bash

set -e

[ "$DEBUG" == "true" ] && set -x

apk add openssl aria2

DATA_DIR=/data
CHAINDATA_DIR=$DATA_DIR/geth/chaindata
EXPECTED_CHECKSUM=b8b13f93cba9bb5b4f62d1586a10ae3b9615a3975e129503ab8692dff698bae0

#if [[ -n $SNAPSHOT && ! -d "$CHAINDATA_DIR" ]]; then
#  echo "restoring from snapshot: $SNAPSHOT"
#
#  apk add zstd lz4
#  rm -rf $DATA_DIR/geth;

  # extract with lz4 (https://github.com/bnb-chain/bsc-snapshots)
#  if echo "$SNAPSHOT" | grep -q "tar\.lz4$"; then
#    wget -c $SNAPSHOT -O - | lz4 -cd | tar xf - -C $DATA_DIR
#    mv /data/server/data-seed/geth $DATA_DIR/geth
#  fi

  # extract with zstd (https://github.com/48Club/bsc-snapshots)
#  if echo "$SNAPSHOT" | grep -q "tar\.zst$"; then
#    baseName=$(basename "$SNAPSHOT" .tar.zst)
#    dirName=$(echo "$baseName" | sed 's/\.[^.]*$//')
#    wget -c $SNAPSHOT -O - | zstd -cd | tar xf - -C $DATA_DIR
#    aria2c -s4 -x4 -k1024M $SNAPSHOT -o /data/$dirName
#    zstd -cd /data/$dirName | tar xf -
#    openssl sha256 /data/$dirName # checksum verification, optional
#    mv /data/$dirName/geth $DATA_DIR/geth
#  fi
#fi

if [[ -n $SNAPSHOT && ! -f "/data/end" ]]; then
    echo "Restoring from snapshot"

    apk add zstd lz4

    # Extract with zstd
    baseName=$(basename "$SNAPSHOT" .tar.zst)
    file=$(basename "$SNAPSHOT")
    dirName=$(echo "$baseName" | sed 's/\.[^.]*$//')
    
    # Download and extract the snapshot
    if [[ ! -f "$DATA_DIR/$file" ]]; then
    aria2c -c -s4 -x4 -k1024M $SNAPSHOT -d $DATA_DIR --checksum=sha-256=b8b13f93cba9bb5b4f62d1586a10ae3b9615a3975e129503ab8692dff698bae0
    fi 

    echo "checking checksum..."
 #   CHECKSUM=$(openssl sha256 $DATA_DIR/$file)


    echo "uncompressing..."
    zstd -cd $DATA_DIR/$file | tar -xvf - -C $DATA_DIR
    echo "$dirName uncompressed"
    touch /data/ending



    # Move extracted data to $DATA_DIR/geth
    mv /data/$dirName/geth $DATA_DIR/geth
    echo "$dirName moved"
    touch /data/end
  
fi



if [ ! -d "$CHAINDATA_DIR" ]; then
  geth init --datadir $DATA_DIR genesis.json
fi

# add static peers
PEERS=$(curl -s https://api.binance.org/v1/discovery/peers | jq -r '.peers | @csv')
if [[ -n "$PEERS" && "$PEERS" != "null" ]]; then
  sed -i -e "s|StaticNodes = \[|StaticNodes = [$PEERS,|" config.toml
fi

# hard reset existing peers
hard_reset_peers() {
  while true; do
    if [[ -e "/data/geth.ipc" ]]; then
      geth --exec '
        for (i=0; i<admin.peers.length; i++) {
          const enode = admin.peers[i].enode
          if (admin.removePeer(enode)) {
            console.log("sucessfully removed peer: ", enode)
          } else {
            console.log("failed to remove peer: ", enode)
          }
        }' attach /data/geth.ipc
      break
    else
      sleep 1
    fi
  done
}

start() {
  geth \
    --config config.toml \
    --datadir $DATA_DIR \
    --http \
    --http.addr 0.0.0.0 \
    --http.port 8545 \
    --http.api eth,net,web3,debug,txpool,parlia \
    --http.vhosts '*' \
    --http.corsdomain '*' \
    --ws \
    --ws.addr 0.0.0.0 \
    --ws.port 8546 \
    --ws.api eth,net,web3,debug,txpool,parlia \
    --ws.origins '*' \
    --syncmode full \
    --maxpeers 200 \
    --rpc.allow-unprotected-txs \
    --txpool.pricelimit 1 \
    --history.transactions 0 \
    --cache 8000 \
    --nat none &
  PID="$!"

  hard_reset_peers &
}

stop() {
  echo "Catching signal and sending to PID: $PID" && kill $PID
  while $(kill -0 $PID 2>/dev/null); do sleep 1; done
}

trap 'stop' TERM INT
start
wait $PID