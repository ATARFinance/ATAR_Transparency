pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./SpaceMarket.sol";

/**
 * @title TimedSpaceMarket
 * @dev SpaceMarket accepting contributions only within a time frame.
 */
contract TimedSpaceMarket is SpaceMarket {
    using SafeMath for uint256;

    uint256 private _openingTime;
    uint256 private _closingTime;


    /**
     * Event for crowdsale extending
     * @param newClosingTime new closing time
     * @param prevClosingTime old closing time
     */
    event TimedSpaceMarketExtended(uint256 prevClosingTime, uint256 newClosingTime);

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen(), "TimedSpaceMarket: not open");
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param openingTime SpaceMarket opening time
     * @param closingTime SpaceMarket closing time
     */
    constructor (uint256 openingTime, uint256 closingTime) public {
        // solhint-disable-next-line not-rely-on-time
        require(openingTime >= block.timestamp, "TimedSpaceMarket: opening time is before current time");
        // solhint-disable-next-line max-line-length
        require(closingTime > openingTime, "TimedSpaceMarket: opening time is not before closing time");

        _openingTime = openingTime;
        _closingTime = closingTime;
    }




    /**
     * @return the crowdsale opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTime;
    }

    /**
     * @dev Extend parent behavior requiring to be within contributing period.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal onlyWhileOpen view {
        super._preValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @dev Extend crowdsale.
     * @param newClosingTime SpaceMarket closing time
     */
    function extendTime(uint256 newClosingTime) public onlyOwner {
        require(!hasClosed(), "TimedSpaceMarket: already closed");
        // solhint-disable-next-line max-line-length
        require(newClosingTime > _closingTime, "TimedSpaceMarket: new closing time is before current closing time");

        emit TimedSpaceMarketExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
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