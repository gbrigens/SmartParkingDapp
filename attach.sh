#!/bin/bash
NUMBER_OF_NODES=5
NODE_NUMBER=$1
case "$NODE_NUMBER" in ("" | *[!0-9]*)
  echo 'Please provide the number of the node to attach to (i.e. ./attach.sh 2)' >&2
  exit 1
esac

if [ "$NODE_NUMBER" -lt 1 ] || [ "$NODE_NUMBER" -gt $NUMBER_OF_NODES ]; then
  echo "$NODE_NUMBER is not a valid node number. Must be between 1 and $NUMBER_OF_NODES." >&2
  exit 1
fi
BIN_GETH=/Users/geraldbirgen/.quorum-wizard/bin/quorum/2.7.0/geth
BIN_TESSERA=/Users/geraldbirgen/.quorum-wizard/bin/tessera/0.10.5/tessera-app.jar

$BIN_GETH attach qdata/dd$1/geth.ipc