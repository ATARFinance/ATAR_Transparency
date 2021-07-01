pragma solidity ^0.5.0;

import "./Context.sol";
import "./IBEP20.sol";
import "./SafeMath.sol";
import "./SafeBEP20.sol";
import "./ReentrancyGuard.sol";
import "./AggregatorV3Interface.sol";
import "./Ownable.sol";

/// @author - Penname - Colonel-PP.
// SPDX-License-Identifier: UNLICENSED

/**
 * @title SpaceMarket
 * @dev SpaceMarket is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract SpaceMarket is Context, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    AggregatorV3Interface internal priceFeed;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 public ten_e18 = 1000000000000000000;
    uint256 public maxToken = 100000;
    // Maximum cap per contribution (token)
    uint256 private _cap;
    // Storage real left cap from presale (token)
    uint256 private _leftcap;
    // Burned cap from presale (token)
    uint256 private _burncap;
    // Transfered cap from presale (token)
    uint256 private _tokenRaised;
    // The token being sold
    IBEP20 private _token;

    uint256 private _closeTime;
    // Address where funds are collected
    address payable private _wallet;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and dollar price in blockchain.
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokensHoldToBurn(address indexed purchaser, address indexed beneficiary, uint256 value);

    /**
     * @dev The rate is the conversion between wei pricefeed
     * get data from aggregatorV3Interface we can list price from blockchain
     * @param wallet Address where collected funds will be forwarded to
     * @param token Address of the token being sold
     * @param __cap is a cap setup max cap
     */
    constructor (address payable wallet, IBEP20 token, uint256 __cap, uint256 __closeTime) public {
        priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
        _rate = uint256(getThePrice()).mul(10);
        // Declare here 1 ATAR always = 0.1$ Surprise right :) told u we fair
        require(_rate > 0, "SpaceMarket: rate is 0, Check proxy contract");
        //How happen ? this is chainlink proxy smart contract ... it's never die on smart contract that's all
        require(wallet != address(0), "SpaceMarket: wallet is the zero address");
        require(address(token) != address(0), "SpaceMarket: token is the zero address");

        _wallet = wallet;
        _token = token;
        _cap = __cap;
        _leftcap = _cap;
        _closeTime = __closeTime;
    }

    function getmaxToken() public view returns (uint256)
    {
        return (maxToken.mul(ten_e18));
    }

    function getCap() public view returns (uint256) {
        return _cap;
    }

    function setCap(uint256 newCap) internal
    {
        require(newCap >= 0, 'New cap must equal or greater than 0');
        _cap = newCap;
    }

    function setBurnCap(uint256 newCap) internal
    {
        require(newCap >= 0, 'New burncap must equal or greater than 0');
        _burncap = newCap;
    }

    function getLeftCap() public view returns (uint256) {
        return _leftcap;
    }

    function getBurnCap() public view returns (uint256) {
        return _burncap;
    }

    function getTokenRaised() public view returns (uint256) {
        return _tokenRaised;
    }


    /**
    * @dev get price function
    * This will update a rate in contract
    * by calculating from BNB / USD price
    * Everyone will get in equality for 0.1$ per ATAR depends on BNB Price (Fair)
    */

    function getThePrice() public view returns (int) {

        (
        uint80 roundID,
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
        // This Price is 10^8
    }



    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    function() external payable {
        buyTokens(_msgSender());
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IBEP20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }


    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _rate = uint256(getThePrice()).mul(10);

        //Update the price first
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        require((tokens) <= getmaxToken(), "Exceed amount of buyer max at specific amount of tokens");
        //        require(tokens.div(10) > 4000 , "Exceed amount of buyer max at specific 4000 dollars");
        // update state
        _weiRaised = _weiRaised.add(weiAmount);
        _tokenRaised = _tokenRaised.add(tokens);
        _leftcap = getCap().sub(_tokenRaised);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, tokens);

        _forwardFunds();
        _postValidatePurchase(beneficiary, tokens);
    }

    function flushToBurnTokens() public nonReentrant onlyOwner payable {
        require(block.timestamp > _closeTime,'Cannot Flush, SpaceMarket sale not end yet');
        _leftcap = getCap().sub(_tokenRaised);
        //See how much we got cap left

        //Send to wallet waiting for burn all left
        _processPurchase(BURN_ADDRESS, _leftcap);

        /**
        * @dev will call this later or someone can call this anyway it's good / Dev call dev paid gas
        * the reason that not automatic call because who call first they have to pay gas fee more
        */
        emit TokensHoldToBurn(_msgSender(), BURN_ADDRESS, _leftcap);

        _updatePurchasingState(BURN_ADDRESS, _leftcap);
        _postValidatePurchase(BURN_ADDRESS, _leftcap);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from SpaceMarket to extend their validations.
     * Example from CappedSpaceMarket_orig.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "SpaceMarket: beneficiary is the zero address");
        require(weiAmount != 0, "SpaceMarket: weiAmount is 0");
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) public view returns (uint256) {
        uint256 converted_rate = _rate.div(100000000);
        // 8 dec -> 4 dec

        return weiAmount.mul(converted_rate);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }


}

/* (,                                         %@&(#@@(                                              ,(
* &@ /@@@@@@@@#(*,,,@@@@/  %@@@@# .. #    %     ...   .%         ( ,. #@@@@%  /@@@@,,**(#@@@@@@@@/ @@
*   #%&@@@@@@@@@&&%%#@@@@@@  &@@@@@   #    *  @       @(@       %   &@@@@&  @@@@@&#%%&&@@@@@@@@@&%#
* &@ *@@@@@&&&&&@@. .,**, *@ &.,@@@   ,        @      ,.@@      *   @@@,.& @* ,**,. .@@&&&&&@@@@@* @&
*      .. .#&@@@@@@ #@@@@%%@**.%@@@   /       /(   ,   &@@.     #   @@@%.**@%%@@@@# @@@@@@&#. .
*     %@ (@@@@@@@(  @/ (((%@@@ &@@@%  #      % &,%/ &% @*@@     (  %@@@@ @@@%((( /@  #@@@@@@@( @%
*          ,@@@@@@@@@@@@ &@@%&@@@@%@&  ,@  %@@ @&.@(/@&((@.@&@@.  &@%@@@@&%@@& @@@@@@@@@@@@,
*           @@@*  .*@@@@@@&. .&&.*@@@@@ #/@@@@@@@@@@@@@@@@@@&&% @@@@@*.&&. .&@@@@@@*.  *@@@
*                #@(/,  /@@@@%,*@# #@@#,@/#C.O.L.O.N.E.L.-P.P.@@,%@@# #@*,%@@@@/  ,/(@#
*                      @@@&&@@@@@@@ % @ @(%..................@@ @ % @@@@@@@&&@@@
*                          @@@@(/@(@@@@@@#%(%@@@%(*,.  .*#&@.@@@@@@@(@/(@@@@
*                                *  (@*,@%%(%@@@%(*,.  .*#&@.@@.*@(  *
*                                   @@@(%&%(%@@@%(*,.  .*#&@.@&(@@@
*                                        @((%@@@%(*,.  .*#&@ #
*                                        &%.%@@@@%*,./%@@@( @@
*                                       *@%#@@@@@%@.@@@%%@@/(@*
*                @&/.*#*               .(@@(@,@#@/  ,.@,@.@/@@..
*          @&&,/%@/&#,& .@%%,#@ @&.#(&%@@#@@@@@#@     @@@@(@@@@@         ,&   &/ .&. *
*          (. (&&/ @/(@*.&,,&% #%@./@%@,% * .. ,%&%%&&,#(#& % .(@&@@@@@@&@ /#@@, @(&/#@*
*              @%@@#(#./&#%.&.%@&*&.,#%(&#&&@&   *&/(&&.,/%*@,@   ./&@@@@@  &@&(.@(&(@(
*
*/