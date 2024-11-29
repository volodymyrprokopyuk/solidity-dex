// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Base} from "util/Base.sol";
import {TokenExchange} from "uniswap-v1/TokenExchange.sol";

contract ExchangeRegistry is Base {
  mapping(address => address) public tokenExchange;
  mapping(address => address) public exchangeToken;
  uint public exchanges;

  event EvCreateExchange(address exchange, address token);

  error ErrExchangeExists(bool exists, address token);

  modifier exchangeExists(bool exists, address token) {
    if (exists && tokenExchange[token] == address(0)) {
      revert ErrExchangeExists(false, token);
    }
    if (!exists && tokenExchange[token] != address(0)) {
      revert ErrExchangeExists(true, token);
    }
    _;
  }

  function createExchange(address token)
    external validAddress(token) exchangeExists(false, token)
    returns (address) {
    TokenExchange exchange = new TokenExchange(token);
    address exchangeAddr = address(exchange);
    tokenExchange[token] = exchangeAddr;
    exchangeToken[exchangeAddr] = token;
    exchanges++;
    emit EvCreateExchange(exchangeAddr, token);
    return exchangeAddr;
  }
}
