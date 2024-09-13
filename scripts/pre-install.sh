#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info

# check for dependencies
if command -v yq >/dev/null 2>&1 ; then
  echo "yq found"
else
  echo "yq not found, please install"
  echo "sudo apt-get install yq"
  exit
fi

if command -v dialog >/dev/null 2>&1 ; then
  echo "dialog found"
else
  echo "dialog not found, please install"
  echo "sudo apt-get install dialog"
  exit
fi

if command -v helm >/dev/null 2>&1 ; then
  echo "helm found"
else
  echo "helm not found, please install"
  echo "sudo snap install helm --classic"
  exit
fi

if command -v kubectl >/dev/null 2>&1 ; then
  echo "kubectl found"
else
  echo "kubectl not found, please install"
  echo "sudo snap install kubectl --classic"
  exit
fi

if helm plugin list | grep diff >/dev/null 2>&1 ; then
  echo "helm diff found"
else
  echo "helm diff not found, please install"
  echo "helm plugin install https://github.com/databus23/helm-diff"
  exit
fi

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
