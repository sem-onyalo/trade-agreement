pragma solidity ^0.4.17;

contract TradeAgreement {
    address public owner;
    uint public totalTokens;
    mapping(bytes32 => Trade) public trades;
    mapping(address => uint32) public accountTokens;

    enum TradeStatus {
        None,
        Pending,
        Active,
        Complete,
        InDispute
    }

    enum TradeAccountStatus {
        None,
        Pending,
        ApproveStart,
        ApproveComplete
    }

    struct Trade {
        bool exists;
        uint8 tradeStatus;
        uint8 tradeTokenFee;
        byte tradeAccountStatus;
    }

    /**
     * Constructor
     *
     * Initializes contract with the contract owner
     */
    function TradeAgreement() public {
        owner = msg.sender;
        totalTokens = 0;
    }

    /**
     * increaseTotalTokens
     *
     * Adds to the total supply of tokens if the sender is the owner
     *
     * @param tokens The tokens to add to the total current supply
     */
    function increaseTotalTokens(uint tokens) public returns (bool success) {
        require(msg.sender == owner);
        require(totalTokens + tokens <= ~uint(0));
        totalTokens += tokens;
        return true;
    }

    /**
     * startTrade
     *
     * Starts a bilateral trade for a specified category
     *
     * @param category The category to which the trade agreement belongs
     * @param sideOne Side one of the trade agreement
     * @param sideTwo Side two of the trade agreement
     * @param tradeTokenFee The token fee to be paid to both parties when the trade agreement is complete
     */
    function startTrade(string category, address sideOne, address sideTwo, uint8 tradeTokenFee) public returns (bool) {
        bytes32 tradeHash = keccak256(sideOne, sideTwo, category);
        require(!trades[tradeHash].exists || (trades[tradeHash].exists && trades[tradeHash].tradeStatus == uint8(TradeStatus.Complete)));
        require(totalTokens >= tradeTokenFee);

        trades[tradeHash] = Trade(true, uint8(TradeStatus.Pending), tradeTokenFee, hex"00");
        totalTokens -= tradeTokenFee;
        return true;
    }

    /**
     * getTradeExists
     *
     * Determines whether or not a trade for the specified category and parties exists
     *
     * @param category The category to which the trade agreement belongs
     * @param sideOne Side one of the trade agreement
     * @param sideTwo Side two of the trade agreement
     */
    function getTradeExists(string category, address sideOne, address sideTwo) public view returns (bool) {
        bytes32 tradeHash = keccak256(sideOne, sideTwo, category);
        return trades[tradeHash].exists;
    }

    /**
     * getTradeStatus
     *
     * Gets the trade status for the specified category and trade parties
     *
     * @param category The category to which the trade agreement belongs
     * @param sideOne Side one of the trade agreement
     * @param sideTwo Side two of the trade agreement
     */
    function getTradeStatus(string category, address sideOne, address sideTwo) public view returns (TradeStatus) {
        bytes32 tradeHash = keccak256(sideOne, sideTwo, category);
        require(trades[tradeHash].exists);
        return TradeStatus(trades[tradeHash].tradeStatus);
    }

    /**
     * getTradeSideOneStatus
     *
     * Gets the trade account status for side one
     *
     * @param category The category to which the trade agreement belongs
     * @param sideOne Side one of the trade agreement
     * @param sideTwo Side two of the trade agreement
     */
    function getTradeSideOneStatus(string category, address sideOne, address sideTwo) public view returns (TradeAccountStatus) {
        bytes32 tradeHash = keccak256(sideOne, sideTwo, category);
        require(trades[tradeHash].exists);

        if (trades[tradeHash].tradeAccountStatus & hex"04" == 4) { // bit 2 takes precedence over bit 0
            return TradeAccountStatus.ApproveComplete;
        } else if (trades[tradeHash].tradeAccountStatus & hex"01" == 0) {
            return TradeAccountStatus.Pending;
        } else if (trades[tradeHash].tradeAccountStatus & hex"01" == 1) {
            return TradeAccountStatus.ApproveStart;
        } else {
            return TradeAccountStatus.None;
        }
    }

    /**
     * getTradeSideTwoStatus
     *
     * Gets the trade account status for side two
     *
     * @param category The category to which the trade agreement belongs
     * @param sideOne Side one of the trade agreement
     * @param sideTwo Side two of the trade agreement
     */
    function getTradeSideTwoStatus(string category, address sideOne, address sideTwo) public view returns (TradeAccountStatus) {
        bytes32 tradeHash = keccak256(sideOne, sideTwo, category);
        require(trades[tradeHash].exists);

        if (trades[tradeHash].tradeAccountStatus & hex"08" == 8) { // bit 3 takes precedence over bit 1
            return TradeAccountStatus.ApproveComplete;
        } else if (trades[tradeHash].tradeAccountStatus & hex"02" == 0) {
            return TradeAccountStatus.Pending;
        } else if (trades[tradeHash].tradeAccountStatus & hex"02" == 2) {
            return TradeAccountStatus.ApproveStart;
        } else {
            return TradeAccountStatus.None;
        }
    }

    /**
     * setTradeSideOneStatus
     *
     * Sets the trade account status for side one
     *
     * @param status The trade account status
     * @param category The category to which the trade agreement belongs
     * @param otherSide The other side of the trade agreement
     */
    function setTradeSideOneStatus(TradeAccountStatus status, string category, address otherSide) public returns (bool) {
        bytes32 tradeHash = keccak256(msg.sender, otherSide, category);
        require(trades[tradeHash].exists);

        if (status == TradeAccountStatus.ApproveStart) {
            return setTradeAccountStatus(status, category, msg.sender, otherSide, tradeHash, hex"01");
        } else if (status == TradeAccountStatus.ApproveComplete) {
            return setTradeAccountStatus(status, category, msg.sender, otherSide, tradeHash, hex"04");
        }
    }

    /**
     * setTradeSideTwoStatus
     *
     * Sets the trade account status for side two
     *
     * @param status The trade account status
     * @param category The category to which the trade agreement belongs
     * @param otherSide The other side of the trade agreement
     */
    function setTradeSideTwoStatus(TradeAccountStatus status, string category, address otherSide) public returns (bool) {
        bytes32 tradeHash = keccak256(otherSide, msg.sender, category);
        require(trades[tradeHash].exists);

        if (status == TradeAccountStatus.ApproveStart) {
            return setTradeAccountStatus(status, category, otherSide, msg.sender, tradeHash, hex"02");
        } else if (status == TradeAccountStatus.ApproveComplete) {
            return setTradeAccountStatus(status, category, otherSide, msg.sender, tradeHash, hex"08");
        }
    }

    // ------------------------------------------------------------------------------------------
    //  INTERNAL FUNCTIONS
    // ------------------------------------------------------------------------------------------

    /**
     * setTradeAccountStatus
     *
     * Sets the trade account status
     *
     * @param status The trade account status
     * @param category The category to which the trade agreement belongs
     * @param sideOne Side one of the trade agreement
     * @param sideTwo Side two of the trade agreement
     * @param tradeHash The trade hash
     * @param bitPosition The bit position to check 
     */
    function setTradeAccountStatus(TradeAccountStatus status, string category, address sideOne, address sideTwo, bytes32 tradeHash, byte bitPosition) internal returns (bool) {
        if (status == TradeAccountStatus.ApproveStart && getTradeSideTwoStatus(category, sideOne, sideTwo) == TradeAccountStatus.Pending
            && getTradeStatus(category, sideOne, sideTwo) == TradeStatus.Pending) {
            trades[tradeHash].tradeAccountStatus |= bitPosition;
            updateTradeStatus(tradeHash);
            return true;
        } else if (status == TradeAccountStatus.ApproveComplete && getTradeSideTwoStatus(category, sideOne, sideTwo) == TradeAccountStatus.ApproveStart
            && getTradeStatus(category, sideOne, sideTwo) == TradeStatus.Active) {
            trades[tradeHash].tradeAccountStatus |= bitPosition;
            updateTradeStatus(tradeHash);

            if (trades[tradeHash].tradeStatus == uint8(TradeStatus.Complete)) {
                accountTokens[sideOne] += trades[tradeHash].tradeTokenFee;
                accountTokens[sideTwo] += trades[tradeHash].tradeTokenFee;
            }
            return true;
        }
    }

    /**
     * updateTradeStatus
     *
     * Updates the trade status with the specified hasg
     *
     * @param tradeHash The trade hash
     */
    function updateTradeStatus(bytes32 tradeHash) internal {
        if (trades[tradeHash].tradeAccountStatus & hex"03" == 3 && trades[tradeHash].tradeStatus == uint8(TradeStatus.Pending)) {
            trades[tradeHash].tradeStatus = uint8(TradeStatus.Active);
        } else if (trades[tradeHash].tradeAccountStatus & hex"0C" == 12 && trades[tradeHash].tradeStatus == uint8(TradeStatus.Active)) {
            trades[tradeHash].tradeStatus = uint8(TradeStatus.Complete);
        }
    }
}