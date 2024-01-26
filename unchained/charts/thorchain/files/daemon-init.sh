#!/bin/sh

sleep 60
mnemonic_file="/root/successful.sh"

if [ -f "$mnemonic_file" ]; then
  echo "mnemonic exists"
  exit 0
else 
  mnemonic=$(thornode generate | grep MASTER_MNEMONIC | cut -d '=' -f 2 | tr -d '\r')
  export SIGNER_SEED_PHRASE=$mnemonic
  echo "successful"
  touch successful.sh
fi

echo "initializing..."
./scripts/fullnode.sh
echo "done"