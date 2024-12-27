// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { UD60x18, ud, uUNIT, mul, sqrt} from "prb-math/UD60x18.sol";
import { SD59x18, sd, div, sqrt } from "prb-math/SD59x18.sol";
import "../src/libs/MintRich20PriceLib.sol";

contract FixedTest is Test {    

    function testERC20Price() public view {
        testERC20Price(2e18);
        testERC20Price(4e18);
        testERC20Price(6e18);
        testERC20Price(8e18);
    }

    function testERC20Price(uint256 totalTokenPrices) private view {
        uint256 totalTokenETH = totalTokenPrices/1e18; // 8 ETH
        uint256 price0 = MintRich20PriceLib.totalTokenPrices(0, 1, totalTokenETH);
        uint256 price1 = MintRich20PriceLib.totalTokenPrices(2e7 - 1, 1, totalTokenETH);
        uint256 price2 = MintRich20PriceLib.totalTokenPrices(5e7 - 1, 1, totalTokenETH);
        uint256 price3 = MintRich20PriceLib.totalTokenPrices(1e8 - 1, 1, totalTokenETH);
        uint256 price4 = MintRich20PriceLib.totalTokenPrices(2e8 - 1, 1, totalTokenETH);
        uint256 price5 = MintRich20PriceLib.totalTokenPrices(3e8 - 1, 1, totalTokenETH);
        uint256 price6 = MintRich20PriceLib.totalTokenPrices(4e8 - 1, 1, totalTokenETH);
        uint256 price7 = MintRich20PriceLib.totalTokenPrices(5e8 - 1, 1, totalTokenETH);
        uint256 maxPrice = MintRich20PriceLib.totalTokenPrices(8e8 - 1, 1, totalTokenETH);

        uint256 totalTokenPrice = MintRich20PriceLib.totalTokenPrices(0, 8e8, totalTokenETH);
        assertEq(totalTokenPrice, totalTokenPrices, "totalTokenPrice not match");
        assertEq(maxPrice/price0, 33, "price curve should not change");
        assertEq(maxPrice/price1, 30, "price curve should not change");
        assertEq(maxPrice/price2, 26, "price curve should not change");
        assertEq(maxPrice/price3, 20, "price curve should not change");
        assertEq(maxPrice/price4, 10, "price curve should not change");
        assertEq(maxPrice/price5, 4, "price curve should not change");
        assertEq(maxPrice/price6, 1, "price curve should not change");
        assertEq(maxPrice/price7, 1, "price curve should not change");
        console.log("erc20PriceLib passed,  totalTokenPrices -> %d", totalTokenPrices);
    }

}