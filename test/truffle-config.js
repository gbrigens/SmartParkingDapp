var LOCAL_HOST = "127.0.0.1";
var QM_PORT = 50401;

module.exports = {
    networks: {
        development: {
            host: LOCAL_HOST,
            port: 22000,
            network_id: "*",
            gasPrice: 0,
            gas: 4500000
        },        
        nodeone: {
            host: LOCAL_HOST,
            port: 22001,
            network_id: "*",
            gasPrice: 0,
            gas: 4500000
        },        
        nodetwo: {
            host: LOCAL_HOST,
            port: 22002,
            network_id: "*",
            gasPrice: 0,
            gas: 4500000
        },        
        nodethree: {
            host: LOCAL_HOST,
            port: 22003,
            network_id: "*",
            gasPrice: 0,
            gas: 4500000
        },        
        nodefour: {
            host: LOCAL_HOST,
            port: 22004,
            network_id: "*",
            gasPrice: 0,
            gas: 4500000
        }
    }
}

// "nodes": [
//     {
//       "quorum": {
//         "ip": "127.0.0.1",
//         "devP2pPort": 21000,
//         "rpcPort": 22000,
//         "wsPort": 23000,
//         "raftPort": 50401,
//         "graphQlPort": 24000
//       },
//       "tm": {
//         "ip": "127.0.0.1",
//         "thirdPartyPort": 9081,
//         "p2pPort": 9001
//       }
//     },
//     {
//       "quorum": {
//         "ip": "127.0.0.1",
//         "devP2pPort": 21001,
//         "rpcPort": 22001,
//         "wsPort": 23001,
//         "raftPort": 50402,
//         "graphQlPort": 24001
//       },
//       "tm": {
//         "ip": "127.0.0.1",
//         "thirdPartyPort": 9082,
//         "p2pPort": 9002
//       }
//     },
//     {
//       "quorum": {
//         "ip": "127.0.0.1",
//         "devP2pPort": 21002,
//         "rpcPort": 22002,
//         "wsPort": 23002,
//         "raftPort": 50403,
//         "graphQlPort": 24002
//       },
//       "tm": {
//         "ip": "127.0.0.1",
//         "thirdPartyPort": 9083,
//         "p2pPort": 9003
//       }
//     },
//     {
//       "quorum": {
//         "ip": "127.0.0.1",
//         "devP2pPort": 21003,
//         "rpcPort": 22003,
//         "wsPort": 23003,
//         "raftPort": 50404,
//         "graphQlPort": 24003
//       },
//       "tm": {
//         "ip": "127.0.0.1",
//         "thirdPartyPort": 9084,
//         "p2pPort": 9004
//       }
//     },
//     {
//       "quorum": {
//         "ip": "127.0.0.1",
//         "devP2pPort": 21004,
//         "rpcPort": 22004,
//         "wsPort": 23004,
//         "raftPort": 50405,
//         "graphQlPort": 24004
//       },
//       "tm": {
//         "ip": "127.0.0.1",
//         "thirdPartyPort": 9085,
//         "p2pPort": 9005
//       }
//     }
//   ],