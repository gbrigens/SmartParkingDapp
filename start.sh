#!/bin/bash
echo "
Starting Quorum network...
"
BIN_GETH=/Users/geraldbirgen/.quorum-wizard/bin/quorum/2.7.0/geth
BIN_TESSERA=/Users/geraldbirgen/.quorum-wizard/bin/tessera/0.10.5/tessera-app.jar

java  -Xms128M -Xmx128M -jar $BIN_TESSERA -configfile qdata/c1/tessera-config-09-1.json >> qdata/logs/tessera1.log 2>&1 &
java  -Xms128M -Xmx128M -jar $BIN_TESSERA -configfile qdata/c2/tessera-config-09-2.json >> qdata/logs/tessera2.log 2>&1 &
java  -Xms128M -Xmx128M -jar $BIN_TESSERA -configfile qdata/c3/tessera-config-09-3.json >> qdata/logs/tessera3.log 2>&1 &
java  -Xms128M -Xmx128M -jar $BIN_TESSERA -configfile qdata/c4/tessera-config-09-4.json >> qdata/logs/tessera4.log 2>&1 &
java  -Xms128M -Xmx128M -jar $BIN_TESSERA -configfile qdata/c5/tessera-config-09-5.json >> qdata/logs/tessera5.log 2>&1 &

echo "Waiting until all Tessera nodes are running..."
DOWN=true
k=10
while ${DOWN}; do
    sleep 1
    DOWN=false
    for i in `seq 1 5`
    do
        if [ ! -S "qdata/c${i}/tm.ipc" ]; then
            echo "Node ${i} is not yet listening on tm.ipc"
            DOWN=true
        fi
    done
    set +e
    #NOTE: if using https, change the scheme
    #NOTE: if using the IP whitelist, change the host to an allowed host
    
    result1=$(curl -s http://127.0.0.1:9001/upcheck)
    if [ ! "${result1}" == "I'm up!" ]; then
        echo "Node 1 is not yet listening on http"
        DOWN=true
    fi
    result2=$(curl -s http://127.0.0.1:9002/upcheck)
    if [ ! "${result2}" == "I'm up!" ]; then
        echo "Node 2 is not yet listening on http"
        DOWN=true
    fi
    result3=$(curl -s http://127.0.0.1:9003/upcheck)
    if [ ! "${result3}" == "I'm up!" ]; then
        echo "Node 3 is not yet listening on http"
        DOWN=true
    fi
    result4=$(curl -s http://127.0.0.1:9004/upcheck)
    if [ ! "${result4}" == "I'm up!" ]; then
        echo "Node 4 is not yet listening on http"
        DOWN=true
    fi
    result5=$(curl -s http://127.0.0.1:9005/upcheck)
    if [ ! "${result5}" == "I'm up!" ]; then
        echo "Node 5 is not yet listening on http"
        DOWN=true
    fi

    k=$((k - 1))
    if [ ${k} -le 0 ]; then
        echo "Tessera is taking a long time to start.  Look at the Tessera logs in qdata/logs/ for help diagnosing the problem."
    fi
    echo "Waiting until all Tessera nodes are running..."

    sleep 5
done

echo "All Tessera nodes started"

echo "Starting Quorum nodes"
PRIVATE_CONFIG=qdata/c1/tm.ipc nohup $BIN_GETH --datadir qdata/dd1 --nodiscover --rpc --rpccorsdomain=* --rpcvhosts=* --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul,quorumPermission --ws --wsaddr 0.0.0.0 --wsorigins=* --emitcheckpoints --unlock 0 --password qdata/dd1/keystore/password.txt --allow-insecure-unlock --graphql --graphql.port 24000 --graphql.corsdomain=* --graphql.addr 0.0.0.0 --istanbul.blockperiod 5 --syncmode full --mine --minerthreads 1 --permissioned --verbosity 5 --networkid 10 --rpcport 22000 --wsport 23000 --port 21000 2>>qdata/logs/1.log &
PRIVATE_CONFIG=qdata/c2/tm.ipc nohup $BIN_GETH --datadir qdata/dd2 --nodiscover --rpc --rpccorsdomain=* --rpcvhosts=* --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul,quorumPermission --ws --wsaddr 0.0.0.0 --wsorigins=* --emitcheckpoints --unlock 0 --password qdata/dd2/keystore/password.txt --allow-insecure-unlock --graphql --graphql.port 24001 --graphql.corsdomain=* --graphql.addr 0.0.0.0 --istanbul.blockperiod 5 --syncmode full --mine --minerthreads 1 --permissioned --verbosity 5 --networkid 10 --rpcport 22001 --wsport 23001 --port 21001 2>>qdata/logs/2.log &
PRIVATE_CONFIG=qdata/c3/tm.ipc nohup $BIN_GETH --datadir qdata/dd3 --nodiscover --rpc --rpccorsdomain=* --rpcvhosts=* --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul,quorumPermission --ws --wsaddr 0.0.0.0 --wsorigins=* --emitcheckpoints --unlock 0 --password qdata/dd3/keystore/password.txt --allow-insecure-unlock --graphql --graphql.port 24002 --graphql.corsdomain=* --graphql.addr 0.0.0.0 --istanbul.blockperiod 5 --syncmode full --mine --minerthreads 1 --permissioned --verbosity 5 --networkid 10 --rpcport 22002 --wsport 23002 --port 21002 2>>qdata/logs/3.log &
PRIVATE_CONFIG=qdata/c4/tm.ipc nohup $BIN_GETH --datadir qdata/dd4 --nodiscover --rpc --rpccorsdomain=* --rpcvhosts=* --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul,quorumPermission --ws --wsaddr 0.0.0.0 --wsorigins=* --emitcheckpoints --unlock 0 --password qdata/dd4/keystore/password.txt --allow-insecure-unlock --graphql --graphql.port 24003 --graphql.corsdomain=* --graphql.addr 0.0.0.0 --istanbul.blockperiod 5 --syncmode full --mine --minerthreads 1 --permissioned --verbosity 5 --networkid 10 --rpcport 22003 --wsport 23003 --port 21003 2>>qdata/logs/4.log &
PRIVATE_CONFIG=qdata/c5/tm.ipc nohup $BIN_GETH --datadir qdata/dd5 --nodiscover --rpc --rpccorsdomain=* --rpcvhosts=* --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul,quorumPermission --ws --wsaddr 0.0.0.0 --wsorigins=* --emitcheckpoints --unlock 0 --password qdata/dd5/keystore/password.txt --allow-insecure-unlock --graphql --graphql.port 24004 --graphql.corsdomain=* --graphql.addr 0.0.0.0 --istanbul.blockperiod 5 --syncmode full --mine --minerthreads 1 --permissioned --verbosity 5 --networkid 10 --rpcport 22004 --wsport 23004 --port 21004 2>>qdata/logs/5.log &

echo "Successfully started Quorum network."
echo "--------------------------------------------------------------------------------

Tessera Node 1 public key:
BULeR8JyUWhiuuCMU/HLA0Q5pzkYT+cHII3ZKBey3Bo=

Tessera Node 2 public key:
QfeDAys9MPDs2XHExtc84jKGHxZg/aj52DTh0vtA3Xc=

Tessera Node 3 public key:
1iTZde/ndBHvzhcl7V68x44Vx7pl8nwx9LqnM/AfJUg=

Tessera Node 4 public key:
oNspPPgszVUFw0qmGFfWwh1uxVUXgvBxleXORHj07g8=

Tessera Node 5 public key:
R56gy4dn24YOjwyesTczYa8m5xhP6hF2uTMCju/1xkY=

--------------------------------------------------------------------------------
"