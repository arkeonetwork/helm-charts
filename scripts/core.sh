#!/usr/bin/env bash

source ./scripts/menu.sh

# reset=$(tput sgr0)              # normal text
reset=$'\e[0m'                  # (works better sometimes)
bold=$(tput bold)               # make colors bold/bright
red="$bold$(tput setaf 1)"      # bright red text
green=$(tput setaf 2)           # dim green text
boldgreen="$bold$green"         # bright green text
fawn=$(tput setaf 3)            # dark yellow text
beige="$fawn"                   # dark yellow text
yellow="$bold$fawn"             # bright yellow text
boldyellow="$bold$yellow"       # bright yellow text
darkblue=$(tput setaf 4)        # dim blue text
blue="$bold$darkblue"           # bright blue text
purple=$(tput setaf 5)          # magenta text
magenta="$purple"               # magenta text
pink="$bold$purple"             # bright magenta text
darkcyan=$(tput setaf 6)        # dim cyan text
cyan="$bold$darkcyan"           # bright cyan text
gray=$(tput setaf 7)            # dim white text
darkgray="$bold"$(tput setaf 0) # bold black = dark gray text
white="$bold$gray"              # bright white text

warn() {
  echo >&2 "$boldyellow:: $*$reset"
}

die() {
  echo >&2 "$red:: $*$reset"
  exit 1
}

confirm() {
  if [ -z "${TC_NO_CONFIRM-}" ]; then
    echo -n "$boldyellow:: Are you sure? Confirm [y/n]: $reset" && read -r ans && [ "${ans:-N}" != y ] && exit
  fi
  echo
}

get_node_net() {
  if [ "$NET" != "" ]; then
    if [ "$NET" != "mainnet" ]; then
      die "Error NET variable=$NET. NET variable should be 'mainnet'."
    fi
    return
  fi
  echo "=> Select net"
  menu mainnet mainnet
  NET=$MENU_SELECTED
  echo
}

get_node_name() {
  [ "$NAME" != "" ] && return
  case $NET in
    "mainnet")
      NAME=arkeo
      ;;
  esac
  read -r -p "=> Enter arkeonode name [$NAME]: " name
  NAME=${name:-$NAME}
  echo
}

get_node_info() {
  get_node_net
  get_node_name
}

get_node_info_short() {
  [ "$NAME" = "" ] && get_node_net
  get_node_name
}

get_node_service() {
  [ "$SERVICE" != "" ] && return
  echo "=> Select arkeonode service"
  menu arkeo arkeo sentinel binance-daemon dogecoin-daemon gaia-daemon avalanche-daemon ethereum-daemon bitcoin-daemon litecoin-daemon bitcoin-cash-daemon
  SERVICE=$MENU_SELECTED
  echo
}

create_namespace() {
  if ! kubectl get ns "$NAME" >/dev/null 2>&1; then
    echo "=> Creating arkeonode Namespace"
    kubectl create ns "$NAME"
    echo
  fi
}

node_exists() {
  kubectl get -n "$NAME" deploy/arkeo >/dev/null 2>&1
}

snapshot_available() {
  kubectl get crd volumesnapshots.snapshot.storage.k8s.io >/dev/null 2>&1
}

generate_mnemonic() {
  echo "=> Generating arkeonode Mnemonic phrase using image registry.gitlab.com/thorchain/thornode"
  kubectl -n "$NAME" run mnemonic --image="registry.gitlab.com/thorchain/thornode" --restart=Never --command -- /bin/sh -c 'tail -F /dev/null'
  kubectl wait --for=condition=ready pods mnemonic -n "$NAME" --timeout=5m >/dev/null 2>&1
  mnemonic=$(kubectl exec -n "$NAME" -it mnemonic -- generate | grep MASTER_MNEMONIC | cut -d '=' -f 2 | tr -d '\r')
  [ "$mnemonic" = "" ] && die "Mnemonic generation failed. Please try again."
  kubectl -n "$NAME" create secret generic arkeo-mnemonic --from-literal=mnemonic="$mnemonic"
  kubectl -n "$NAME" delete pod --now=true mnemonic
  echo
}

create_mnemonic() {
  local mnemonic
  local image
  # Do nothing if mnemonic already exists.
  kubectl -n "${NAME}" get secrets/arkeo-mnemonic >/dev/null 2>&1 && return

  echo "=> Setting arkeonode Mnemonic phrase"
  read -r -s -p "Enter mnemonic (empty to generate): " mnemonic
  echo

  # generate mnemonic if empty
  if [[ ${mnemonic} == "" ]]; then
    generate_mnemonic
    return
  fi

  # validate mnemonic
  read -r -s -p "Confirm mnemonic: " mnemonicconf
  echo
  [[ ${mnemonic} != "${mnemonicconf}" ]] && die "Mnemonics mismatch"

  kubectl -n "${NAME}" create secret generic arkeo-mnemonic --from-literal=mnemonic="${mnemonic}"
}

create_password() {
  local pwd
  local pwdconf
  if ! kubectl get -n "$NAME" secrets/arkeo-password >/dev/null 2>&1; then
    echo "=> Creating arkeonode Password"
    read -r -s -p "Enter password: " pwd
    echo
    read -r -s -p "Confirm password: " pwdconf
    echo
    [ "$pwd" != "$pwdconf" ] && die "Passwords mismatch"
    kubectl -n "$NAME" create secret generic arkeo-password --from-literal=password="$pwd"
    echo
  fi
}

display_mnemonic() {
  kubectl get -n "$NAME" secrets/arkeo-mnemonic --template="{{.data.mnemonic}}" | base64 --decode
  echo
}

display_pods() {
  kubectl get -n "$NAME" pods
}

display_password() {
  kubectl get -n "$NAME" secrets/arkeo-password --template="{{.data.password}}" | base64 --decode
}

display_status() {
  APP=arkeo

  local initialized
  initialized=$(kubectl get pod -n "$NAME" -l app.kubernetes.io/name=$APP -o 'jsonpath={..status.conditions[?(@.type=="Initialized")].status}')
  if [ "$initialized" = "True" ]; then
    local output
    output=$(kubectl exec -it -n "$NAME" deploy/$APP -c $APP -- /scripts/node-status.sh | tee /dev/tty)
    NODE_ADDRESS=$(awk '$1 ~ /ADDRESS/ {match($2, /[a-z0-9]+/); print substr($2, RSTART, RLENGTH)}' <<<"$output")

    if grep -E "^STATUS\s+Active" <<<"$output" >/dev/null; then
      echo -e "\n=> Detected ${red}active$reset validator arkeonode on $boldgreen$NET$reset named $boldgreen$NAME$reset"
    fi
  else
    echo "arkeo pod is not currently running, status is unavailable"
  fi
  return
}

deploy() {
  local args
  [ "$NET" = "mainnet" ] && args="--set global.passwordSecret=arkeo-password"
  helm diff upgrade -C 3 --install "$NAME" ./arkeo-stack -n "$NAME" \
    $args $EXTRA_ARGS \
    --set global.mnemonicSecret=arkeo-mnemonic \
    --set global.net="$NET" \
    --set arkeo.type="validator"
  echo -e "=> Changes for a$boldgreen$TYPE$reset arkeonode on $boldgreen$NET$reset named $boldgreen$NAME$reset"
  confirm
  helm upgrade --install "$NAME" ./arkeo-stack -n "$NAME" \
    --create-namespace $args $EXTRA_ARGS \
    --set global.mnemonicSecret=arkeo-mnemonic \
    --set global.net="$NET" \
    --set arkeo.type="validator"
}
