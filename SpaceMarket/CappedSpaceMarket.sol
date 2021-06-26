pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./SpaceMarket.sol";

/// @author - Penname - Colonel-PP.
// SPDX-License-Identifier: UNLICENSED
/**
 * @title CappedSpaceMarket
 * @dev Extension of SpaceMarket with a max amount of funds raised
 */
contract CappedSpaceMarket is SpaceMarket {
    using SafeMath for uint256;


    constructor( uint256 _setcap ) public
    {
        require(_setcap > 0,'CappedSpaceMarket :: Cap must greather than 0');
        setCap(_setcap);
    }



    // overriding SpaceMarket#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function caphasEnded() public view returns (bool) {
        bool capReached = weiRaised() >= getCap();
        return capReached;
    }

    // overriding SpaceMarket#validPurchase to add extra cap logic
    // @return true if investors can buy at the moment
    function validPurchase() internal view returns (bool) {
        bool withinCap = weiRaised().add(msg.value) <= getCap();
        return withinCap;
    }

}
