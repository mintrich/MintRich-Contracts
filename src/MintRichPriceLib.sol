// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { UD60x18, ud, uUNIT, mul, sqrt} from "prb-math/UD60x18.sol";

library MintRichPriceLib {

    uint256 constant CONST_A = 5e14;
    uint256 constant CONST_B = 5000;
    uint256 constant CONST_C = 3e6;

    function poolBalance(uint256 supply) internal pure returns (uint256 balance){
        uint256 sb = supply < CONST_B ? CONST_B - supply : supply - CONST_B;
        uint256 sqrtV = ud((sb * sb + CONST_C) * uUNIT).sqrt().unwrap();
        balance = mul(ud(sqrtV + supply * uUNIT), ud(CONST_A)).unwrap();
    }

    function totalTokenPrices(uint256 supply, uint256 amount) internal pure returns (uint256 prices) {
        prices = poolBalance(supply + amount) - poolBalance(supply);
    }

}