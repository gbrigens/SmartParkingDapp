var storageTest = artifacts.require("SimpleStorage");

module.exports = function(deployer) {
    deployer.deploy(storageTest, 70, {privateFor: ["QfeDAys9MPDs2XHExtc84jKGHxZg/aj52DTh0vtA3Xc=","1iTZde/ndBHvzhcl7V68x44Vx7pl8nwx9LqnM/AfJUg="]})
}

//SimpleStorage.deployed().then(function(instance){ return instance.get();})