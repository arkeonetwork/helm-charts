#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info_short

if ! node_exists; then
  die "No existing THORNode found, make sure this is the correct name"
fi

if [ "$SERVICE" = "" ]; then
  echo "=> Select a THORNode service to backup"
  menu thornode thornode bifrost
  SERVICE=$MENU_SELECTED
fi

if ! kubectl -n "$NAME" get pvc "$SERVICE" >/dev/null 2>&1; then
  warn "Volume $SERVICE not found"
  echo
  exit 0
fi

make_backup "$SERVICE"

echo
warn "If you plan to restore this backup to a fresh install, see more detailed instructions:"
echo https://gitlab.com/thorchain/devops/node-launcher/-/blob/master/docs/Restore-Validator-Backup.md?ref_type=heads
