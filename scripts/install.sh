#!/usr/bin/env bash

source ./scripts/core.sh
source ./scripts/pre-install.sh

if [ "$0" == "./scripts/update.sh" ] && snapshot_available; then
  make_snapshot "arkeo"
  if [ "$TYPE" != "fullnode" ]; then
    make_snapshot "sentinel"
  fi
fi

case $NET in
  mainnet)
    EXTRA_ARGS="-f ./arkeo-stack/mainnet.yaml"
    ;;
  stagenet)
    EXTRA_ARGS="-f ./arkeo-stack/stagenet.yaml"
    ;;
  testnet)
    EXTRA_ARGS="-f ./arkeo-stack/testnet.yaml"
    ;;
esac

if [ -n "$HARDFORK_BLOCK_HEIGHT" ]; then
  EXTRA_ARGS="$EXTRA_ARGS --set arkeo.haltHeight=$HARDFORK_BLOCK_HEIGHT"
fi
# check to ensure required CRDs are created before deploying
if ! kubectl get crd servicemonitors.monitoring.coreos.com >/dev/null 2>&1; then
  echo "=> Required ServiceMonitor CRD not found - run 'make tools' before proceeding."
  exit 1
fi

deploy
