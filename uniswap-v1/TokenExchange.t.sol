// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Test} from "std/Test.sol";
import {IFungibleToken, FungibleToken} from "erc/FungibleToken.sol";
import {ExchangeFactory} from "uniswap-v1/ExchangeFactory.sol";
import {TokenExchange} from "uniswap-v1/TokenExchange.sol";

contract Token is FungibleToken {
  constructor(string memory nam, string memory sym, uint8 dec)
    FungibleToken(nam, sym, dec) { }

  function mintTokens(address rcp, uint val) external returns (bool) {
    return mint(rcp, val);
  }
}

contract TokenExchangeTest is Test {
  address owner;
  Token token;
  ExchangeFactory factory;
  address exchAddr;
  TokenExchange exchange;

  function setUp() public {
    // Create the TOK to swap
    owner = makeAddr("owner");
    token = new Token("Token", "TOK", 0);
    // Create the TOK exchange
    factory = new ExchangeFactory();
    exchAddr = factory.createExchange(address(token));
    exchange = TokenExchange(exchAddr);
    assertEq(factory.exchanges(), 1);
  }

  function fundToken(address own, address exch, uint val) internal {
    // Mint TOK to the owner
    bool success = token.mintTokens(own, val);
    assertTrue(success);
    // Approve the exchange to transfer TOK on behalf of the owner
    vm.prank(own);
    success = token.approve(exch, val);
    assertTrue(success);
  }

  function testDepositWithdrawLiquidity() public {
    // Fund the owner eth: 100, tok: 200
    uint valEth = 100;
    vm.deal(owner, valEth);
    uint maxTok = 200;
    fundToken(owner, exchAddr, maxTok);
    // Deposit liquidity eth: 100, tok: 200, liq: 100
    uint minLiq = 100;
    vm.expectEmit(true, true, false, true);
    emit TokenExchange.EvLiquidityDeposit(exchAddr, owner, valEth, maxTok, minLiq);
    vm.prank(owner);
    uint valLiq = exchange.depositLiquidity{value: valEth}(maxTok, minLiq);
    assertGe(valLiq, minLiq);
    assertEq(exchAddr.balance, valEth); // Exchange ETH
    assertLe(token.balanceOf(exchAddr), maxTok); // Exchange TOK
    assertEq(owner.balance, 0); // Owner ETH
    assertGe(token.balanceOf(owner), 0); // Owner TOK
    assertEq(exchange.balanceOf(owner), valLiq); // Owner LIQ
    // Withdraw liquidity eth: 100, tok: 200, liq: 100
    uint minEth = 100;
    uint minTok = 200;
    valLiq = 100;
    vm.expectEmit(true, true, false, true);
    emit TokenExchange.EvLiquidityWithdraw(exchAddr, owner, minEth, minTok, valLiq);
    vm.prank(owner);
    uint valTok;
    (valEth, valTok) = exchange.withdrawLiquidity(minEth, minTok, valLiq);
    assertGe(valEth, minEth);
    assertGe(valTok, minTok);
    assertEq(exchAddr.balance, 0); // Exchange ETH
    assertGe(token.balanceOf(exchAddr), 0); // Exchange TOK
    assertGe(owner.balance, minEth);
    assertGe(token.balanceOf(owner), minTok); // Owner TOK
    assertEq(exchange.balanceOf(owner), 0); // Owner LIQ
  }

  function depositLiquidity() internal {
    // Fund the owner eth: 100, tok: 200
    uint valEth = 100;
    vm.deal(owner, valEth);
    uint maxTok = 200;
    fundToken(owner, exchAddr, maxTok);
    // Deposit liquidity eth: 100, tok: 200, liq: 100
    uint minLiq = 100;
    vm.expectEmit(true, true, false, true);
    emit TokenExchange.EvLiquidityDeposit(exchAddr, owner, valEth, maxTok, minLiq);
    vm.prank(owner);
    uint valLiq = exchange.depositLiquidity{value: valEth}(maxTok, minLiq);
    assertEq(exchange.balanceOf(owner), valLiq);
  }

  function testInSwapEthTok() public {
    depositLiquidity();
    uint ownEth = 100;
    vm.deal(owner, ownEth);
    // In swap eth: 40, tok: 80 => 57
    uint valEth = 40;
    uint minTok = 57;
    vm.expectEmit(true, true, true, true);
    emit TokenExchange.EvTokenBuy(exchAddr, owner, owner, valEth, minTok);
    vm.prank(owner);
    uint valTok = exchange.inSwapEthTok{value: valEth}(minTok);
    assertGe(valTok, minTok);
    assertEq(owner.balance, ownEth - valEth); // Owner ETH
    assertEq(token.balanceOf(owner), valTok); // Owner TOK
    // In swap eth: 40, tok: 57 => 31
    uint valEth2 = 40;
    uint minTok2 = 31;
    vm.expectEmit(true, true, true, true);
    emit TokenExchange.EvTokenBuy(exchAddr, owner, owner, valEth2, minTok2);
    vm.prank(owner);
    uint valTok2 = exchange.inSwapEthTok{value: valEth2}(minTok2);
    assertGe(valTok2, minTok2);
    assertEq(owner.balance, ownEth - valEth - valEth2); // Owner ETH
    assertEq(token.balanceOf(owner), valTok + valTok2); // Owner TOK
  }

  function testOutSwapEthTok() public {
    depositLiquidity();
    uint ownEth = 500;
    vm.deal(owner, ownEth);
    // Out swap eth: 40 => 66, tok: 80
    uint valTok = 80;
    uint maxEth = 70; // 66;
    vm.expectEmit(true, true, true, true);
    emit TokenExchange.EvTokenBuy(exchAddr, owner, owner, 66, valTok);
    emit TokenExchange.EvEtherRefund(exchAddr, owner, maxEth - 66);
    vm.prank(owner);
    uint valEth = exchange.outSwapEthTok{value: maxEth}(valTok);
    assertEq(owner.balance, ownEth - valEth); // Owner ETH
    assertEq(token.balanceOf(owner), valTok); // Owner TOK
    // Out swap eth: 66 => 332, tok: 80
    uint valTok2 = 80;
    uint maxEth2 = 340; // 332;
    vm.expectEmit(true, true, true, true);
    emit TokenExchange.EvTokenBuy(exchAddr, owner, owner, 332, valTok2);
    emit TokenExchange.EvEtherRefund(exchAddr, owner, maxEth2 - 332);
    vm.prank(owner);
    uint valEth2 = exchange.outSwapEthTok{value: maxEth2}(valTok2);
    assertEq(owner.balance, ownEth - valEth - valEth2); // Owner ETH
    assertEq(token.balanceOf(owner), valTok + valTok2); // Owner TOK
  }

  function testInSwapTokEth() public {
    depositLiquidity();
    uint ownTok = 200;
    fundToken(owner, exchAddr, ownTok);
    // In swap eth: 40 => 28, tok: 80
    uint valTok = 80;
    uint minEth = 28;
    vm.expectEmit(true, true, true, true);
    emit TokenExchange.EvTokenSell(exchAddr, owner, owner, valTok, minEth);
    vm.prank(owner);
    uint valEth = exchange.inSwapTokEth(valTok, minEth);
    assertGe(valEth, minEth);
    assertEq(owner.balance, valEth); // Owner ETH
    assertEq(token.balanceOf(owner), ownTok - valTok); // Owner TOK
    // In swap eth: 28 => 15, tok: 80
    uint valTok2 = 80;
    uint minEth2 = 15;
    vm.expectEmit(true, true, true, true);
    emit TokenExchange.EvTokenSell(exchAddr, owner, owner, valTok2, minEth2);
    vm.prank(owner);
    uint valEth2 = exchange.inSwapTokEth(valTok2, minEth2);
    assertGe(valEth2, minEth2);
    assertEq(owner.balance, valEth + valEth2); // Owner ETH
    assertEq(token.balanceOf(owner), ownTok - valTok - valTok2); // Owner TOK
  }

  function testOutSwapTokEth() public {
    depositLiquidity();
    uint ownTok = 900;
    fundToken(owner, exchAddr, ownTok);
    // Out swap eth: 40, tok: 80 => 133
    uint valEth = 40;
    uint maxTok = 133;
    vm.expectEmit(true, true, true, true);
    emit TokenExchange.EvTokenSell(exchAddr, owner, owner, maxTok, valEth);
    vm.prank(owner);
    uint valTok = exchange.outSwapTokEth(maxTok, valEth);
    assertLe(valTok, maxTok);
    assertEq(owner.balance, valEth); // Owner ETH
    assertEq(token.balanceOf(owner), ownTok - maxTok); // Owner Eth
    // Out swap eth: 40, tok: 133 => 668
    uint valEth2 = 40;
    uint maxTok2 = 668;
    vm.expectEmit(true, true, true, true);
    emit TokenExchange.EvTokenSell(exchAddr, owner, owner, maxTok2, valEth2);
    vm.prank(owner);
    uint valTok2 = exchange.outSwapTokEth(maxTok2, valEth2);
    assertLe(valTok2, maxTok2);
    assertEq(owner.balance, valEth + valEth2); // Owner ETH
    assertEq(token.balanceOf(owner), ownTok - maxTok - maxTok2); // Owner Eth
  }
}
