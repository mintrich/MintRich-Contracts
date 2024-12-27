// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { UD60x18, ud, uUNIT, mul, sqrt} from "prb-math/UD60x18.sol";

library MintRich20PriceLib {

    uint256 constant CONST_A_1 = 1.25e9; // totalTokenPrice = 1 ETH
    uint256 constant CONST_A_2 = CONST_A_1 * 2;
    uint256 constant CONST_A_4 = CONST_A_1 * 4;
    uint256 constant CONST_A_6 = CONST_A_1 * 6;
    uint256 constant CONST_A_8 = CONST_A_1 * 8;
    uint256 constant CONST_B = 4e8;    
    uint256 constant CONST_C = 2e16;

    function poolBalance(
        uint256 supply, 
        uint256 constA
    ) 
        internal 
        pure 
        returns (uint256 balance)
    {
        uint256 sb = supply < CONST_B ? CONST_B - supply : supply - CONST_B;
        uint256 sqrtV = ud((sb * sb + CONST_C) * uUNIT).sqrt().unwrap();
        balance = mul(ud(sqrtV + supply * uUNIT), ud(constA)).unwrap();
    }

    function totalTokenPricesV2(
        uint256 supply, 
        uint256 amount
    ) 
        internal 
        pure 
        returns (uint256 prices) 
    {
        prices = poolBalance(supply + amount, CONST_A_2) - poolBalance(supply, CONST_A_2);
    }

    function totalTokenPricesV4(
        uint256 supply, 
        uint256 amount
    ) 
        internal 
        pure 
        returns (uint256 prices) 
    {
        prices = poolBalance(supply + amount, CONST_A_4) - poolBalance(supply, CONST_A_4);
    }

    function totalTokenPricesV6(
        uint256 supply, 
        uint256 amount
    ) 
        internal 
        pure 
        returns (uint256 prices) 
    {
        prices = poolBalance(supply + amount, CONST_A_6) - poolBalance(supply, CONST_A_6);
    }

    function totalTokenPricesV8(
        uint256 supply, 
        uint256 amount
    ) 
        internal 
        pure 
        returns (uint256 prices) 
    {
        prices = poolBalance(supply + amount, CONST_A_8) - poolBalance(supply, CONST_A_8);
    }
}