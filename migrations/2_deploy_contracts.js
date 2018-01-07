var TradeAgreement = artifacts.require("TradeAgreement");

module.exports = function(deployer) {
    deployer.deploy(TradeAgreement);
}