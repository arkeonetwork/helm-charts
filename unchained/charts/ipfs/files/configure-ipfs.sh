#!/bin/sh

set -e
set -x

user=ipfs

# This is a custom entrypoint for k8s designed to run ipfs nodes in an appropriate
# setup for production scenarios.

mkdir -p /data/ipfs && chown -R ipfs /data/ipfs

if [ -f /data/ipfs/config ]; then
  if [ -f /data/ipfs/repo.lock ]; then
    rm /data/ipfs/repo.lock
  fi
  exit 0
fi

ipfs init --profile=server
ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080
ipfs config --json Swarm.ConnMgr.HighWater 10000
ipfs config --json Swarm.ConnMgr.LowWater 2500
ipfs config --json Swarm.ConnMgr.GracePeriod 20s
ipfs config --json Internal.Bitswap.EngineBlockstoreWorkerCount 2500
ipfs config --json Internal.Bitswap.EngineTaskWorkerCount 500
ipfs config --json Internal.Bitswap.MaxOutstandingBytesPerPeer 1048576
ipfs config --json Internal.Bitswap.TaskWorkerCount 500
ipfs config --json Datastore.BloomFilterSize 1048576
ipfs config Datastore.StorageMax 100GB