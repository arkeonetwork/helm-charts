#!/bin/sh

    HEALTH=$(wget -q -O - -T 20 localhost:8080/v2/health | grep '\"inSync\": true') || exit 1


    if [[ $HEALTH == '"inSync": true' ]]; then
      echo "midgard is synced"
      exit 0
    fi

    echo "midgard is still syncing"
    exit 1