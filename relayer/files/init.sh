#!/bin/sh

#initialize the relayer config file
  rly config init

#add the chains to the config
   rly chains add --file /arkeo.json arkeo
   rly chains add osmosistestnet --testnet

#add new keys
   rly keys add arkeo arkeokey
   rly keys add osmosistestnet osmokey

#set keys as default 
   rly keys use arkeo arkeokey
   rly keys use osmosistestnet osmokey

#create path
   rly paths new arkeo osmo-test-5 arkeo-osmosistestnet

#create client, connection, channel
   rly tx link arkeo-osmosistestnet -d -t 3s
   sleep 3600
