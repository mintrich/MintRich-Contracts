// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { UD60x18, ud, uUNIT, mul, sqrt} from "prb-math/UD60x18.sol";
import { SD59x18, sd, div, sqrt } from "prb-math/SD59x18.sol";

contract FixedTest is Test {

    int256 constant iUNIT = int256(uUNIT);
    
    uint256 constant CONST_A = 1e10;
    uint256 constant CONST_B = 4e8;
    uint256 constant CONST_C = 2e16;

    function testTokenPrice() public view {
        uint256 b0 = poolBalance(8e8);
        uint256 b1 = poolBalance(0);
        console.logUint(b0 - b1);
    }

    function testPriceSeq() public view {
        uint256 price = poolBalance(1) - poolBalance(0);
        console.logUint(price);

        uint256 price2 = poolBalance(8e8) - poolBalance(8e8 - 1);
        console.logUint(price2);
    }

    function poolBalance(uint256 supply) internal pure returns (uint256 balance){
        uint256 sb = supply < CONST_B ? CONST_B - supply : supply - CONST_B;
        uint256 sqrtV = ud((sb * sb + CONST_C) * uUNIT).sqrt().unwrap();
        balance = mul(ud(sqrtV + supply * uUNIT), ud(CONST_A)).unwrap();
    }

}