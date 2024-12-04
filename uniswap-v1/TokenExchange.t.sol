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
  address exchAddr;
  TokenExchange exch;

  function setUp() public {
    own = makeAddr("owner");
    tok = new Token(own, initSupp, "Token", "TOK", 0);
    fact = new ExchangeFactory();
    exchAddr = fact.createExchange(address(tok));
    exch = TokenExchange(exchAddr);
    assertEq(fact.exchanges(), 1);
    vm.prank(own);
    bool succ = tok.approve(exchAddr, initSupp);
    assertTrue(succ);
  }

  function testDepositWithdrawLiquidity() public {
    // Fund owner
    uint ownEth = 150;
    vm.deal(own, ownEth);
    // First liquidity deposit eth: 100, tok: 200, liq: 100
    uint valEth = 100;
    uint maxTok = 200;
    uint minLiq = valEth;
    vm.expectEmit(true, true, false, true);
    emit TokenExchange.EvLiquidityDeposit(exchAddr, own, valEth, maxTok, minLiq);
    vm.prank(own);
    uint valLiq = exch.depositLiquidity{value: valEth}(maxTok, minLiq);
    uint exchEth = valEth;
    uint exchTok = maxTok;
    uint ownLiq = minLiq;
    assertEq(valLiq, minLiq);
    assertEq(exchAddr.balance, exchEth); // Exchange ETH
    assertEq(tok.balanceOf(exchAddr), exchTok); // Exchange TOK
    assertEq(exch.balanceOf(own), ownLiq); // Owner LIQ
    // Second liquidity deposit eth: 50, tok: 100: liq: 50
    valEth = 50;
    maxTok = 100;
    minLiq = 50;
    vm.prank(own);
    valLiq = exch.depositLiquidity{value: valEth}(maxTok, minLiq);
    exchEth += valEth;
    exchTok += maxTok;
    ownLiq += minLiq;
    assertEq(valLiq, minLiq);
    assertEq(exchAddr.balance, exchEth); // Exchange ETH
    assertEq(tok.balanceOf(exchAddr), exchTok); // Exchange TOK
    assertEq(exch.balanceOf(own), ownLiq); // Owner LIQ
    // First liquidity withdrawal eth: 100, tok: 200, liq: 100
    uint minEth = 100;
    uint minTok = 200;
    valLiq = 100;
    vm.expectEmit(true, true, false, true);
    emit TokenExchange.EvLiquidityWithdraw(exchAddr, own, minEth, minTok, valLiq);
    vm.prank(own);
    uint valTok;
    (valEth, valTok) = exch.withdrawLiquidity(minEth, minTok, valLiq);
    exchEth -= minEth;
    exchTok -= minTok;
    ownLiq -= valLiq;
    assertEq(valEth, minEth);
    assertEq(valTok, minTok);
    assertEq(exchAddr.balance, exchEth); // Exchange ETH
    assertEq(tok.balanceOf(exchAddr), exchTok); // Exchange TOK
    assertEq(exch.balanceOf(own), ownLiq); // Owner LIQ
    // Second liquidity withdrawal eth: 50, tok: 100, liq: 50
    minEth = 50;
    minTok = 100;
    valLiq = 50;
    vm.expectEmit(true, true, false, true);
    emit TokenExchange.EvLiquidityWithdraw(exchAddr, own, minEth, minTok, valLiq);
    vm.prank(own);
    (valEth, valTok) = exch.withdrawLiquidity(minEth, minTok, valLiq);
    exchEth -= minEth;
    exchTok -= minTok;
    ownLiq -= valLiq;
    assertEq(valEth, minEth);
    assertEq(valTok, minTok);
    assertEq(exchAddr.balance, exchEth); // Exchange ETH
    assertEq(tok.balanceOf(exchAddr), exchTok); // Exchange TOK
    assertEq(exch.balanceOf(own), ownLiq); // Owner LIQ
  }
}
