// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Base} from "util/Base.sol";
import {TokenExchange} from "uniswap-v1/TokenExchange.sol";

contract ExchangeFactory is Base {
  mapping(address tok => address exch) public tokenExchange;
  mapping(address exch => address tok) public exchangeToken;
  uint public exchanges;
  uint internal feePermille = 3; // 0.3% fee

  event EvExchangeCreate(address exch, address tok);

  error ErrExchangeExists(bool exists, address tok);

  function exchangeExists(bool exists, address tok) internal view {
    if (exists && tokenExchange[tok] == address(0)) {
      revert ErrExchangeExists(false, tok);
    }
    if (!exists && tokenExchange[tok] != address(0)) {
      revert ErrExchangeExists(true, tok);
    }
  }

  function createExchange(address tok) external returns (address) {
    validAddress(tok); exchangeExists(false, tok);
    TokenExchange exch = new TokenExchange(tok, feePermille);
    address exchAddr = address(exch);
    tokenExchange[tok] = exchAddr;
    exchangeToken[exchAddr] = tok;
    exchanges++;
    emit EvExchangeCreate(exchAddr, tok);
    return exchAddr;
  }
}
