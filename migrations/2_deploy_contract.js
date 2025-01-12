const DecentralizedDataSharing = artifacts.require("contracts/DecentralizedDataSharing");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(DecentralizedDataSharing, accounts[0]);
};