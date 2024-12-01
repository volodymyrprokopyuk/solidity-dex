// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Base} from "util/Base.sol";
import {TokenExchange} from "uniswap-v1/TokenExchange.sol";

contract ExchangeFactory is Base {
  mapping(address tok => address exch) public tokenExchange;
  mapping(address exch => address tok) public exchangeToken;
  uint public exchanges;

  event EvCreateExchange(address exch, address tok);

  error ErrExchangeExists(bool exists, address tok);

  modifier exchangeExists(bool exists, address tok) {
    if (exists && tokenExchange[tok] == address(0)) {
      revert ErrExchangeExists(false, tok);
    }
    if (!exists && tokenExchange[tok] != address(0)) {
      revert ErrExchangeExists(true, tok);
    }
    _;
  }

  function createExchange(address tok)
    external validAddress(tok) exchangeExists(false, tok)
    returns (address) {
    TokenExchange exch = new TokenExchange(tok);
    address exchAddr = address(exch);
    tokenExchange[tok] = exchAddr;
    exchangeToken[exchAddr] = tok;
    exchanges++;
    emit EvCreateExchange(exchAddr, tok);
    return exchAddr;
  }
}
