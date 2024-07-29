#!/bin/bash

# read list of chains from values.yaml
CHAINS="$(yq '.blockchains' ../unchained/values.yaml)"

#echo $CHAINS

# convert true = on
CHAINS=${CHAINS//true/on}
# convert false = off
CHAINS=${CHAINS//false/off}
# strip :
CHAINS=${CHAINS//:/}

#echo $CHAINS

# display dialog selector of chains
exec 3>&1
NEWCHAINS=$(dialog --ok-label "LFG" --no-cancel --no-items --checklist  'Choose Your Blockchains!' 0 0 0 $CHAINS 2>&1 1>&3)

# strip on
CHAINS=${CHAINS//on/}
# strip off
CHAINS=${CHAINS//off/}

# update values.yaml with the selections as 'true'

echo $CHAINS
echo $NEWCHAINS

# build yq command to inline update blockchains.x 

for CHAIN in $CHAINS
do 
  if [[ $NEWCHAINS =~ "$CHAIN" ]]; then
	yq -i '.blockchains.'$CHAIN' |= true' ../unchained/values.yaml
  else
	yq -i '.blockchains.'$CHAIN' |= false' ../unchained/values.yaml
  fi
done

