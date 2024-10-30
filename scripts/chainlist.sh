#!/bin/bash

# read list of chains from values.yaml, strip quotes
CHAINS="$(yq 'to_entries | .[] | .key' unchained/values.yaml)"
CHAINS=${CHAINS//\"/}

# build chain string
for CHAIN in $CHAINS
do
  if [[ $CHAIN != "global" && $CHAIN != "etherscan_api_key" && $CHAIN != "\"\"" ]]; then
    chainList+="$CHAIN $(yq '.'$CHAIN'.enabled' unchained/values.yaml) "
    chainList=${chainList//true/on}
    chainList=${chainList//false/off}
  fi
done

# display dialog selector of chains
exec 3>&1
NEWCHAINS=$(dialog --ok-label "LFG" --no-cancel --no-items --checklist 'Choose Your Blockchains!' 0 0 0 $chainList 2>&1 1>&3)

#echo $NEWCHAINS

# build yq command to inline update blockchains
for CHAIN in $CHAINS
do
  if [[ $CHAIN != "global" && $CHAIN != "etherscan_api_key" ]]; then
    if [[ $NEWCHAINS =~ "$CHAIN" ]]; then
	yq -yi '.'$CHAIN'[] = true' unchained/values.yaml
    else
	yq -yi '.'$CHAIN'[] = false' unchained/values.yaml
    fi
  fi
done
