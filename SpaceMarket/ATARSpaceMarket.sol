pragma solidity ^0.5.0;

/// @author - Penname - Colonel-PP.
// SPDX-License-Identifier: UNLICENSED

import "./PostDeliverySpaceMarket.sol";
import "./CappedSpaceMarket.sol";
import "./IBEP20.sol";
import "./SafeMath.sol";


contract ATARSpaceMarket is SpaceMarket ,CappedSpaceMarket , TimedSpaceMarket ,PostDeliverySpaceMarket {

    // Address for store contribution amount
    mapping(address => uint256) private _contributions;

    constructor(
        uint256 cap,
        uint256 openingTime,
        uint256 closingTime,
        address payable wallet,
        IBEP20 token
    )
    public
    SpaceMarket(wallet, token, cap,closingTime)
    CappedSpaceMarket(cap)
    TimedSpaceMarket(openingTime, closingTime)
    {
        setCap(cap);
    }



    /**
     * @dev Returns the amount contributed so far by a specific beneficiary.
     * @param beneficiary Address of contributor
     * @return Beneficiary contribution so far
     */
    function getContribution(address beneficiary) public view returns (uint256) {
        return _contributions[beneficiary];
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the beneficiary's funding cap.
     * @param beneficiary Token purchaser
     * @param tokenAmount Amount of token contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 tokenAmount) internal view {
        super._preValidatePurchase(beneficiary, tokenAmount);
        // solhint-disable-next-line max-line-length
        require(
            _contributions[beneficiary].add(tokenAmount) <= getCap(),
            "SpaceMarket: beneficiary's cap exceeded"
        );

        require(
            ((_contributions[beneficiary]).add(tokenAmount)) <= getmaxToken(),
            "SpaceMarket: beneficiary's buying total exceeded specific 4000 Dollars"
        );
        require(validPurchase() == true,'SpaceMarket: Amount you add might exceed a cap please check again');
    }

    /**
     * @dev Extend parent behavior to update beneficiary contributions.
     * @param beneficiary Token purchaser
     * @param tokenAmount Amount of token contributed
     */
    function _updatePurchasingState(address beneficiary, uint256 tokenAmount) internal {
        super._updatePurchasingState(beneficiary, tokenAmount);
        _contributions[beneficiary] = _contributions[beneficiary].add(
            tokenAmount
        );
    }

    // overriding SpaceMarket#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return caphasEnded() || hasClosed();
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