// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { UD60x18, ud, uUNIT, mul, sqrt} from "prb-math/UD60x18.sol";
import { SD59x18, sd, div, sqrt } from "prb-math/SD59x18.sol";

contract FixedTest is Test {

    int256 constant iUNIT = int256(uUNIT);
    
    uint256 constant CONST_A = 1e15;
    uint256 constant CONST_B = 4000;
    uint256 constant CONST_C = 4e6;

    // function testFixed() public view {
    //     for (uint256 i = 1; i <= 10; i++) {
    //         UD60x18 udn = ud(i * uUNIT);
    //         console.log("%s -> %s", i, sqrt(udn).unwrap());
    //     }
    // }

    // function testPrice() public view {
    //     for (int256 i = 0; i <= 10; i++) {
    //         int256 sdn = (div(sd(int256(i - 5000) * iUNIT), 
    //             sd((3000000 + int256(i - 5000) * int256(i - 5000)) * iUNIT).sqrt()).unwrap()
    //                 + 1 * iUNIT) * 5e14 / iUNIT;
    //         console.logInt(sdn);
    //     }
    // }

    function testTokenPrice() public view {
        uint256 b0 = poolBalance(8000);
        uint256 b1 = poolBalance(0);
        console.logUint(b0 - b1);
    //     uint256 b1 = poolBalance(1);
    //     console.logUint(b1);
    //     uint256 b2 = poolBalance(2);
    //     console.logUint(b2);
    //     uint256 b3 = poolBalance(3);
    //     console.logUint(b3);
    //     uint256 b4 = poolBalance(4);
    //     console.logUint(b4);

    //     uint256 price1 = b1 - b0;
    //     uint256 price2 = b2 - b1;
    //     uint256 price3 = b3 - b2;
    //     uint256 price4 = b4 - b3;
    //     console.logUint(price1);
    //     console.logUint(price2);
    //     console.logUint(price3);
    //     console.logUint(price4);

    //     uint256 p1 = price2 - price1;
    //     uint256 p2 = price3 - price2;
    //     uint256 p3 = price4 - price3;
    //     console.logUint(p1);
    //     console.logUint(p2);
    //     console.logUint(p3);
    }

    function testPriceSeq() public view {
        for (uint256 s = 1;s <= 8000;s++) {
             uint256 price = poolBalance(s) - poolBalance(s - 1);
             console.logUint(price);
        }
    }

    function poolBalance(uint256 supply) internal pure returns (uint256 balance){
        uint256 sb = supply < CONST_B ? CONST_B - supply : supply - CONST_B;
        uint256 sqrtV = ud((sb * sb + CONST_C) * uUNIT).sqrt().unwrap();
        balance = mul(ud(sqrtV + supply * uUNIT), ud(CONST_A)).unwrap();
    }

}