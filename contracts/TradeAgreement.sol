pragma solidity ^0.4.17;

contract TradeAgreement {
    address public owner;
    uint256 public totalTokens;
    mapping(bytes32 => Trade) public trades;
    mapping(address => uint32) public accountTokens;

    enum TokenSource {
        Contract
        //Account
    }

    enum TradeStatus {
        Pending,
        Active,
        Complete,
        InDispute
    }

    enum AccountTradeStatus {
        Pending,
        StartApproved,
        EndApproved
    }

    struct Trade {
        bool exists;
        TradeStatus tradeStatus;
        TokenSource tokenSource;
        address sideOne;
        address sideTwo;
        AccountTradeStatus sideOneStatus;
        AccountTradeStatus sideTwoStatus;
        uint8 sideOneTokenFee;
        uint8 sideTwoTokenFee;
    }

    /**
     * Constructor
     *
     * Initializes contract with an initial supply of tokens and the contract owner
     */
    function TradeAgreement(uint256 tokens) public {
        owner = msg.sender;
        totalTokens = tokens;
    }

    /**
     * increaseTotalRepTokens
     *
     * Adds to the total supply of tokens if the sender is the owner
     */
    function increaseTotalRepTokens(uint256 tokens) public returns (bool success) {
        require(msg.sender == owner);
        require(totalTokens + tokens <= ~uint256(0));
        totalTokens += tokens;
        return true;
    }

    /**
     * startTrade
     *
     * Starts a bilateral trade for a specified category
     *
     * @param category The category to which the trade agreement belongs
     * @param tokenSource The source from which to pay out the tokens when the trade agreement is complete
     * @param sideOne Side one of the trade agreement
     * @param sideTwo Side two of the trade agreement
     * @param sideOneTokenFee The token fee to be paid to side one when the trade agreement is complete
     * @param sideTwoTokenFee The token fee to be paid to side two when the trade agreement is complete
     */
    function startTrade(string category, TokenSource tokenSource, address sideOne, address sideTwo, uint8 sideOneTokenFee, uint8 sideTwoTokenFee) public returns (bool success) {
        bytes32 tradeHash = keccak256(sideOne, sideTwo, category);
        uint16 totalTokenFee = sideOneTokenFee + sideTwoTokenFee;
        require(!trades[tradeHash].exists || (trades[tradeHash].exists && trades[tradeHash].tradeStatus == TradeStatus.Complete));
        require(totalTokens >= totalTokenFee);

        trades[tradeHash] = Trade(true, TradeStatus.Pending, tokenSource, sideOne, sideTwo, AccountTradeStatus.Pending, AccountTradeStatus.Pending, sideOneTokenFee, sideTwoTokenFee);
        totalTokens -= totalTokenFee;
        return true;
    }

    /**
     * setSideOneTradeStatus
     *
     * Sets the trade status based on the specified status from side one
     *
     * @param status The specified status from side one
     * @param category The category to which the trade agreement belongs
     * @param otherSide The other side in the trade agreement
     */
    function setSideOneTradeStatus(AccountTradeStatus status, string category, address otherSide) public returns (bool success) {
        bytes32 tradeHash = keccak256(msg.sender, otherSide, category);
        require(trades[tradeHash].exists);

        if (status == AccountTradeStatus.StartApproved && trades[tradeHash].sideOneStatus == AccountTradeStatus.Pending && trades[tradeHash].tradeStatus == TradeStatus.Pending) {
            trades[tradeHash].sideOneStatus = status;
            if (trades[tradeHash].sideTwoStatus == AccountTradeStatus.StartApproved) {
                trades[tradeHash].tradeStatus = TradeStatus.Active;
            }
            return true;
        } else if (status == AccountTradeStatus.EndApproved && trades[tradeHash].sideOneStatus == AccountTradeStatus.StartApproved && trades[tradeHash].tradeStatus == TradeStatus.Active) {
            trades[tradeHash].sideOneStatus = status;
            if (trades[tradeHash].sideTwoStatus == AccountTradeStatus.EndApproved) {
                trades[tradeHash].tradeStatus = TradeStatus.Complete;
            }
            return true;
        } else if (status == AccountTradeStatus.Pending && trades[tradeHash].sideOneStatus != AccountTradeStatus.Pending && trades[tradeHash].tradeStatus == TradeStatus.Active) {
            trades[tradeHash].sideOneStatus = status;
            trades[tradeHash].tradeStatus = TradeStatus.InDispute;
            return true;
        }
    }

    /**
     * setSideTwoTradeStatus
     *
     * Sets the trade status based on the specified status from side two
     *
     * @param status The specified status from side two
     * @param category The category to which the trade agreement belongs
     * @param otherSide The other side in the trade agreement
     */
    function setSideTwoTradeStatus(AccountTradeStatus status, string category, address otherSide) public returns (bool success) {
        bytes32 tradeHash = keccak256(otherSide, msg.sender, category);
        require(trades[tradeHash].exists);

        if (status == AccountTradeStatus.StartApproved && trades[tradeHash].sideTwoStatus == AccountTradeStatus.Pending && trades[tradeHash].tradeStatus == TradeStatus.Pending) {
            trades[tradeHash].sideTwoStatus = status;
            if (trades[tradeHash].sideOneStatus == AccountTradeStatus.StartApproved) {
                trades[tradeHash].tradeStatus = TradeStatus.Active;
            }
            return true;
        } else if (status == AccountTradeStatus.EndApproved && trades[tradeHash].sideTwoStatus == AccountTradeStatus.StartApproved && trades[tradeHash].tradeStatus == TradeStatus.Active) {
            trades[tradeHash].sideTwoStatus = status;
            if (trades[tradeHash].sideOneStatus == AccountTradeStatus.EndApproved) {
                return completeTradeAgreement(tradeHash);
            }
            return true;
        } else if (status == AccountTradeStatus.Pending && trades[tradeHash].sideTwoStatus != AccountTradeStatus.Pending && trades[tradeHash].tradeStatus == TradeStatus.Active) {
            trades[tradeHash].sideTwoStatus = status;
            trades[tradeHash].tradeStatus = TradeStatus.InDispute;
            return true;
        }
    }

    // ------------------------------------------------------------------------------------------
    //  INTERNAL FUNCTIONS
    // ------------------------------------------------------------------------------------------

    /**
     * completeTradeAgreement
     *
     * Completes a trade agreement and transfers tokens to the parties involved
     *
     * @param tradeHash The hash for the trade agreement
     */
    function completeTradeAgreement(bytes32 tradeHash) internal returns (bool success) {
        require(accountTokens[trades[tradeHash].sideOne] + trades[tradeHash].sideOneTokenFee <= ~uint32(0));
        require(accountTokens[trades[tradeHash].sideTwo] + trades[tradeHash].sideTwoTokenFee <= ~uint32(0));

        if (trades[tradeHash].tokenSource == TokenSource.Contract) {
            accountTokens[trades[tradeHash].sideOne] += trades[tradeHash].sideOneTokenFee;
            accountTokens[trades[tradeHash].sideTwo] += trades[tradeHash].sideTwoTokenFee;
            trades[tradeHash].tradeStatus = TradeStatus.Complete;            
            return true;
        }
    }
}