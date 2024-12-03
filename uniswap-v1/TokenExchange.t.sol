// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {IFungibleToken, FungibleToken} from "erc/FungibleToken.sol";
import {ExchangeFactory} from "uniswap-v1/ExchangeFactory.sol";
import {TokenExchange} from "uniswap-v1/TokenExchange.sol";

contract Token is FungibleToken {
  constructor(
    address own, uint initSupp, string memory nam, string memory sym, uint8 dec
 ) FungibleToken(own, initSupp, nam, sym, dec) { }
}

contract TokenExchangeTest is Test {
  address own;
  uint initSupp = 1000;
  IFungibleToken tok;
  ExchangeFactory fact;
  TokenExchange exch;

  function setUp() public {
    own = makeAddr("owner");
    tok = new Token(own, initSupp, "Token", "TOK", 0);
    fact = new ExchangeFactory();
    exch = TokenExchange(fact.createExchange(address(tok)));
    assertEq(fact.exchanges(), 1);
  }

  function testA() public pure {
    assertTrue(true);
  }
}
