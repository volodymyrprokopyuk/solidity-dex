// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Base} from "util/Base.sol";
// import {LiquidityToken} from "uniswap-v1/LiquidityToken.sol";

// contract TokenExchange is LiquidityToken {
contract TokenExchange is Base {
  address public registry;
  address public token;

  constructor(address tok) validAddress(tok) {
    registry = msg.sender;
    token = tok;
  }
}
