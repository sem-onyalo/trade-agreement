var tokenSupply = 1000000;
var tradeCategory = "";
var tradeTokenFee = 50;
var TradeAgreement = artifacts.require("TradeAgreement");

var enums = {
    TradeStatus: {
        None: 0,
        Pending: 1,
        Active: 2,
        Complete: 3,
        InDispute: 4
    },
    TradeAccountStatus: {
        None: 0,
        Pending: 1,
        ApproveStart: 2,
        ApproveComplete: 3
    }
};

contract('TradeAgreement', function(accounts) {
    it('should add to total token supply', function() {
        return TradeAgreement.deployed().then(function(instance) {
            instance.increaseTotalTokens(tokenSupply);
            return instance.totalTokens();
        }).then(function(totalTokens) {
            assert.equal(totalTokens, tokenSupply, 'Token supply was not set to supplied value');
        });
    });

    it('should create a new trade object', function() {
        return TradeAgreement.deployed().then(function(instance){
            instance.startTrade(tradeCategory, accounts[0], accounts[1], tradeTokenFee);
            return instance.getTradeExists(tradeCategory, accounts[0], accounts[1]);
        }).then(function(exists) {
            assert.equal(exists, true, 'Trade object was not created');
        });
    });

    it('should have a trade status of pending', function() {
        return TradeAgreement.deployed().then(function(instance) {
            return instance.getTradeStatus(tradeCategory, accounts[0], accounts[1]);
        }).then(function(tradeStatus) {
            assert.equal(tradeStatus.valueOf(), enums.TradeStatus.Pending, 'Trade status was not set to pending');
        });
    });

    it('should have a trade account status of Pending for side one of trade', function() {
        return TradeAgreement.deployed().then(function(instance) {
            return instance.getTradeSideOneStatus(tradeCategory, accounts[0], accounts[1]);
        }).then(function(tradeAccountStatus) {
            assert.equal(tradeAccountStatus.valueOf(), enums.TradeAccountStatus.Pending, 'Trade account status was not set to Pending for side one');
        });
    });

    it('should have a trade account status of Pending for side two of trade', function() {
        return TradeAgreement.deployed().then(function(instance) {
            return instance.getTradeSideTwoStatus(tradeCategory, accounts[0], accounts[1]);
        }).then(function(tradeAccountStatus) {
            assert.equal(tradeAccountStatus.valueOf(), enums.TradeAccountStatus.Pending, 'Trade account status was not set to Pending for side two');
        });
    });

    it('should have a trade account status of ApproveStart for side one of trade', function() {
        return TradeAgreement.deployed().then(function(instance) {
            instance.setTradeSideOneStatus(enums.TradeAccountStatus.ApproveStart, tradeCategory, accounts[1], {from: accounts[0]});
            return instance.getTradeSideOneStatus(tradeCategory, accounts[0], accounts[1]);
        }).then(function(tradeAccountStatus) {
            assert.equal(tradeAccountStatus.valueOf(), enums.TradeAccountStatus.ApproveStart, 'Trade account status was not set to ApproveStart for side one')
        });
    });

    it('should have a trade account status of ApproveStart for side two of trade', function() {
        return TradeAgreement.deployed().then(function(instance) {
            instance.setTradeSideTwoStatus(enums.TradeAccountStatus.ApproveStart, tradeCategory, accounts[0], {from: accounts[1]});
            return instance.getTradeSideTwoStatus(tradeCategory, accounts[0], accounts[1]);
        }).then(function(tradeAccountStatus) {
            assert.equal(tradeAccountStatus.valueOf(), enums.TradeAccountStatus.ApproveStart, 'Trade account status was not set to ApproveStart for side two');
        });
    });

    it('should have a trade status of Active if both sides have approved the start', function() {
        return TradeAgreement.deployed().then(function(instance) {
            return instance.getTradeStatus(tradeCategory, accounts[0], accounts[1]);
        }).then(function(tradeStatus) {
            assert.equal(tradeStatus.valueOf(), enums.TradeStatus.Active, 'Trade status was not set to Active');
        });
    });

    it('should have a trade account status of ApproveComplete for side one of trade', function() {
        return TradeAgreement.deployed().then(function(instance) {
            instance.setTradeSideOneStatus(enums.TradeAccountStatus.ApproveComplete, tradeCategory, accounts[1], {from: accounts[0]});
            return instance.getTradeSideOneStatus(tradeCategory, accounts[0], accounts[1]);
        }).then(function(tradeAccountStatus) {
            assert.equal(tradeAccountStatus.valueOf(), enums.TradeAccountStatus.ApproveComplete, 'Trade account status was not set to ApproveComplete for side one')
        });
    });

    it('should have a trade account status of ApproveComplete for side two of trade', function() {
        return TradeAgreement.deployed().then(function(instance) {
            instance.setTradeSideTwoStatus(enums.TradeAccountStatus.ApproveComplete, tradeCategory, accounts[0], {from: accounts[1]});
            return instance.getTradeSideTwoStatus(tradeCategory, accounts[0], accounts[1]);
        }).then(function(tradeAccountStatus) {
            assert.equal(tradeAccountStatus.valueOf(), enums.TradeAccountStatus.ApproveComplete, 'Trade account status was not set to ApproveComplete for side two');
        });
    });

    it('should have a trade status of Complete if both sides have approved the completion', function() {
        return TradeAgreement.deployed().then(function(instance) {
            return instance.getTradeStatus(tradeCategory, accounts[0], accounts[1]);
        }).then(function(tradeStatus) {
            assert.equal(tradeStatus.valueOf(), enums.TradeStatus.Complete, 'Trade status was not set to Complete');
        });
    });

    it('should have token fee add to side one\'s account tokens once the trade is complete', function() {
        return TradeAgreement.deployed().then(function(instance) {
            return instance.accountTokens(accounts[0]);
        }).then(function(accountTokens) {
            assert.equal(accountTokens, tradeTokenFee, 'Side one\'s account tokens was not increased to the specifed fee on trade completion');
        });
    });

    it('should have token fee add to side two\'s account tokens once the trade is complete', function() {
        return TradeAgreement.deployed().then(function(instance) {
            return instance.accountTokens(accounts[1]);
        }).then(function(accountTokens) {
            assert.equal(accountTokens, tradeTokenFee, 'Side two\'s account tokens was not increased to the specifed fee on trade completion');
        });
    });
});