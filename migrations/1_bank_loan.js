const Bank = artifacts.require("Bank");
module.exports = function (deployer) {
    const initialFunding = web3.utils.toWei("50", "ether");
    deployer.deploy(Bank, { gas: 6721975, value: initialFunding });
    };