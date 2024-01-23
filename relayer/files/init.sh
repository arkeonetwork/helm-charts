#!/bin/sh

#initialize the relayer config file
  rly config init

#add the chains to the config
   rly chains add --file /arkeo.json arkeo
   rly chains add osmosistestnet --testnet

#add new keys
   rly keys restore arkeo arkeokey "{{ .Values.mnemonic.arkeo }}"
   rly keys restore osmosistestnet osmokey "{{ .Values.mnemonic.osmo }}"

#set keys as default 
   rly keys use arkeo arkeokey
   rly keys use osmosistestnet osmokey

#query balance
   rly q balance arkeo
   rly q balance osmosistestnet

#create path
   rly paths new arkeo osmo-test-5 arkeo-osmosistestnet

#create client, connection, channel
   rly tx link arkeo-osmosistestnet -d
   sleep 3600
