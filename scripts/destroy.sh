#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info_short

node_exists || die "No existing Arkeo deployment found, make sure this is the correct name"

display_status

echo -e "=> Destroying a $boldgreen$TYPE$reset Arkeo node on $boldgreen$NET$reset named $boldgreen$NAME$reset"
echo
confirm
echo "=> Deleting Arkeo node"
helm delete "$NAME" -n "$NAME"
kubectl delete namespace "$NAME"
