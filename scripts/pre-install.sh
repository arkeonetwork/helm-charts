#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info

echo "You configure this deployment by editing the ./arkeo-stack/${NET}.yaml file."
echo "If you haven't looked at this file yet, press ^C now and edit it before proceeding."
echo ""

case $NET in
  mainnet)
    EXTRA_ARGS="-f ./relayer/values.yaml"
    ;;
esac

if node_exists; then
  warn "Found an existing arkeoode, make sure this is the node you want to update"
  display_status
  echo
fi

echo -e "=> Deploying a$boldgreen$TYPE$reset arkeonode on $boldgreen$NET$reset named $boldgreen$NAME$reset"
confirm

create_namespace
if [ "$TYPE" != "daemons" ]; then
  create_password
  create_mnemonic
fi

choosechains
