pragma solidity 0.4.19;

import "./common/BaseContract.sol";
import "./common/Owned.sol";
import "./common/TokenRetriever.sol";
import "./BPZSmartToken.sol";
import "./VestingManager.sol";

// solhint-disable not-rely-on-time

/// @title BPC Smart Token sale
contract OldBPZSmartTokenSale is BaseContract, Owned, TokenRetriever {
    using SafeMath for uint256;

    BPZSmartToken public bpz;
    bool public initialized = false;

    uint256 public startTime = 0;
    uint256 public endTime = 0;
    uint256 public tokensPerEther = 25000;
    uint256 public tokensSold = 0;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public tokensPurchased;

    address public companyIssuedTokensAddress;
    address public contributionFundsAddress;
    address public blitzPredictVestingAddress;
    address public teamVestingAddress;
    address public futureHiresVestingAddress;

    uint256 public constant MAX_TOKENS = (10 ** 9) * (10 ** 18);
    uint256 public constant ONE_PERCENT = MAX_TOKENS / 100;
    uint256 public constant SEED_ROUND_TOKENS = 5 * ONE_PERCENT;
    uint256 public constant STRATEGIC_PARTNER_TOKENS = 8 * ONE_PERCENT;
    uint256 public constant ADVISOR_TOKENS = 5 * ONE_PERCENT;
    uint256 public constant LIQUIDITY_RESERVE_TOKENS = 5 * ONE_PERCENT;
    uint256 public constant FUTURE_HIRES_TOKENS = 9 * ONE_PERCENT;
    uint256 public constant TEAM_TOKENS = 18 * ONE_PERCENT;
    uint256 public constant BLITZPREDICT_TOKENS = 20 * ONE_PERCENT;
    uint256 public presaleTokensSold;
    uint256 public totalSellableTokens;

    event Whitelisted(address indexed _participant, uint256 _contributionLimit);
    event TokensPurchased(address indexed _to, uint256 _tokens);

    modifier onlyDuringSale() {
        require(initialized);
        require(tokensSold < totalSellableTokens);
        require(now >= startTime);
        require(now < endTime);

        _;
    }

    modifier onlyBeforeSale() {
        require(initialized);
        require(now < startTime);

        _;
    }

    /// @dev Fallback function -- just purchase tokens
    function ()
        external
        payable
    {
        purchaseTokens();
    }

    /// @dev Sets the number of BPZ that can be purchased for one ether
    function setTokensPerEther(uint256 _tokensPerEther)
        external
        onlyOwner
        onlyBeforeSale
    {
        tokensPerEther = _tokensPerEther;
    }

    /// @dev Initializes all the various fields necessary for running the sale.
    /// @param _bpz address The address of the BPZ token.
    /// @param _vestingManager address The address of the VestingManager.
    /// @param _startTime uint256 The start time of the token sale.
    /// @param _endTime uint256 The end time of the token sale.
    /// @param _presaleTokensSold uint256 The number of tokens sold in presale, in wei.
    /// @param _addresses address[] The various addresses necessary for running the sale.
    function initialize(address _bpz, address _vestingManager, uint256 _startTime, uint256 _endTime, uint256 _presaleTokensSold, address[] _addresses)
        external
        onlyOwner
        onlyIf(!initialized)
        onlyIf(_startTime > now && _endTime > _startTime)
        onlyIf(_addresses.length == 5)
    {
        bpz = BPZSmartToken(_bpz);
        bpz.acceptOwnership();

        startTime = _startTime;
        endTime = _endTime;
        presaleTokensSold = _presaleTokensSold;

        companyIssuedTokensAddress = _addresses[0];
        contributionFundsAddress = _addresses[1];
        blitzPredictVestingAddress = _addresses[2];
        teamVestingAddress = _addresses[3];
        futureHiresVestingAddress = _addresses[4];

        totalSellableTokens = MAX_TOKENS.sub(getCompanyIssuedTokens()).sub(getVestingTokens());
        bpz.issue(companyIssuedTokensAddress, getCompanyIssuedTokens());

        VestingManager vestingManager = VestingManager(_vestingManager);
        bpz.issue(vestingManager, getVestingTokens());

        uint256 oneYear = startTime.add(1 years);
        uint256 twoYears = startTime.add(2 years);
        uint256 threeYears = startTime.add(3 years);

        vestingManager.acceptOwnership();
        vestingManager.grantTokens(futureHiresVestingAddress, FUTURE_HIRES_TOKENS, startTime, oneYear, threeYears);
        vestingManager.grantTokens(teamVestingAddress, TEAM_TOKENS, startTime, oneYear, threeYears);
        vestingManager.grantTokens(blitzPredictVestingAddress, BLITZPREDICT_TOKENS, startTime, oneYear, twoYears);
        vestingManager.transferOwnership(owner);

        initialized = true;
    }

    /// @dev Adds or modifies items in the whitelist
    function updateWhitelist(address[] participants, uint256[] contributionLimits)
        external
        onlyOwner
        onlyIf(participants.length == contributionLimits.length)
    {
        for (uint256 i = 0; i < participants.length; ++i) {
            whitelist[participants[i]] = contributionLimits[i];
            Whitelisted(participants[i], contributionLimits[i]);
        }
    }

    /// @dev Proposes to transfer control of the BPZSmartToken contract to a new owner.
    /// @param newOwner address The address to transfer ownership to.
    ///
    /// Notes:
    ///   1. The new owner will need to call BPZSmartToken's acceptOwnership directly in order to accept the ownership.
    ///   2. Calling this method during the token sale will prevent the token sale to continue, since only the owner of
    ///      the BPZSmartToken contract can issue new tokens.
    ///    3. Due to #2, calling this method effectively pauses the token sale.
    function transferSmartTokenOwnership(address newOwner)
        external
        onlyOwner
    {
        bpz.transferOwnership(newOwner);
    }

    /// @dev Accepts new ownership on behalf of the BPZSmartToken contract. This can be used, by the token sale
    /// contract itself to claim back ownership of the BPZSmartToken contract.
    ///
    /// Notes:
    ///   1. This method must be called to "un-pause" the token sale after a call to transferSmartTokenOwnership
    function acceptSmartTokenOwnership()
        external
        onlyOwner
    {
        bpz.acceptOwnership();
    }

    function getCompanyIssuedTokens()
        public view
        returns (uint256)
    {
        return 0 +
            SEED_ROUND_TOKENS +
            STRATEGIC_PARTNER_TOKENS +
            ADVISOR_TOKENS +
            LIQUIDITY_RESERVE_TOKENS +
            presaleTokensSold;
    }

    function getVestingTokens()
        public pure
        returns (uint256)
    {
        return 0 +
            FUTURE_HIRES_TOKENS +
            TEAM_TOKENS +
            BLITZPREDICT_TOKENS;
    }

     /// @dev Create and sell tokens to the caller.
    function purchaseTokens()
        public
        payable
        onlyDuringSale
        greaterThanZero(msg.value)
    {
        uint256 purchaseLimit = whitelist[msg.sender].mul(tokensPerEther);
        uint256 purchaseLimitRemaining = purchaseLimit.sub(tokensPurchased[msg.sender]);
        require(purchaseLimitRemaining > 0);

        uint256 desiredTokens = msg.value.mul(tokensPerEther);
        uint256 desiredTokensCapped = SafeMath.min256(desiredTokens, purchaseLimitRemaining);
        uint256 tokensRemaining = totalSellableTokens.sub(tokensSold);
        uint256 tokens = SafeMath.min256(desiredTokensCapped, tokensRemaining);
        uint256 contribution = tokens.div(tokensPerEther);

        issuePurchasedTokens(msg.sender, tokens);
        contributionFundsAddress.transfer(contribution);

        // Refund the msg.sender, in the case that not all of its ETH was used.
        // This can happen only when selling the last chunk of BPC.
        uint256 refund = msg.value.sub(contribution);
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
    }

    /// @dev Issues tokens for the recipient.
    /// @param _recipient address The address of the recipient.
    /// @param _tokens uint256 The amount of tokens to issue.
    function issuePurchasedTokens(address _recipient, uint256 _tokens)
        private
    {
        tokensSold = tokensSold.add(_tokens);
        tokensPurchased[msg.sender] = tokensPurchased[msg.sender].add(_tokens);

        bpz.issue(_recipient, _tokens);

        TokensPurchased(_recipient, _tokens);
    }
}
