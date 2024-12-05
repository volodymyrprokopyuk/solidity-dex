// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Base} from "util/Base.sol";
import {IFungibleToken, FungibleToken} from "erc/FungibleToken.sol";

contract TokenExchange is Base, FungibleToken {
  address public factory;
  IFungibleToken public token; // TOK to swap
  uint fee; // 1000 - feePermille

  event EvLiquidityDeposit(
    address indexed exch, address indexed dps, uint eth, uint tok, uint liq
  );
  event EvLiquidityWithdraw(
    address indexed exch, address indexed wdr, uint eth, uint tok, uint liq
  );
  event EvTokenBuy(
    address indexed exch, address indexed byr, address indexed rcp,
    uint eth, uint tok
  );
  event EvTokenSell(
    address indexed exch, address indexed sel, address indexed rcp,
    uint tok, uint eth
  );
  event EvEtherRefund(address indexed exch, address indexed byr, uint eth);

  // Deposit liquidity
  error ErrTokenAboveMax(address exch, address dps, uint val, uint max);
  error ErrLiquidityBelowMin(address exch, address dps, uint val, uint min);
  error ErrLiquidityMint(address exch, address dps, uint val);
  error ErrTokenDeposit(address exch, address dps, uint val);
  // Withdraw liquidity
  error ErrLiquidityAboveTotal(address exch, address wdr, uint val, uint tot);
  error ErrEtherBelowMin(address exch, address wdr, uint val, uint min);
  error ErrTokenBelowMin(address exch, address wdr, uint val, uint min);
  error ErrLiquidityBurn(address exch, address wdr, uint val);
  error ErrTokenWithdraw(address exch, address wdr, uint val);
  error ErrEtherWithdraw(address exch, address wdr, uint val);
  // Swap tokens
  error ErrTokenSwap(address exch, address rcp, uint val);
  error ErrEtherAboveMax(address exch, address byr, uint val, uint max);
  error ErrEtherRefund(address exch, address byr, uint val);
  error ErrEtherSend(address exch, address rcp, uint val);

  constructor(address tok, uint feePermille)
    FungibleToken("Liquidity token", "LIQ", 0) {
    validAddress(address(tok));
    factory = msg.sender;
    token = IFungibleToken(tok);
    fee = 1000 - feePermille;
  }

  function liquidityDeposit(uint maxTok, uint minLiq) internal view
    returns (uint, uint) {
    (address dps, address exch) = (msg.sender, address(this));
    uint valEth = msg.value;
    uint resEth = exch.balance - valEth;
    uint resTok = token.balanceOf(exch);
    uint resLiq = totalSupply;
    uint valTok;
    uint valLiq;
    if (resLiq == 0) {
      // The first depositor sets the TOK price in terms of LIQ
      valTok = maxTok;
      valLiq = valEth;
    } else {
      valTok = valEth * resTok / resEth;
      require(valTok <= maxTok, ErrTokenAboveMax(exch, dps, valTok, maxTok));
      valLiq = valEth * resLiq / resEth;
      require(valLiq >= minLiq, ErrLiquidityBelowMin(exch, dps, valLiq, minLiq));
    }
    return (valTok, valLiq);
  }

  function depositLiquidity(uint maxTok, uint minLiq) external payable
    returns (uint) {
    (address dps, address exch) = (msg.sender, address(this));
    uint valEth = msg.value; // ETH already deposited to the exchange
    positive(valEth); positive(maxTok); positive(minLiq);
    (uint valTok, uint valLiq) = liquidityDeposit(maxTok, minLiq);
    bool success = mint(dps, valLiq); // Mint LIQ to the depositor
    require(success, ErrLiquidityMint(exch, dps, valLiq));
    success = token.transferFrom(dps, exch, valTok); // Deposit TOK to the exchange
    require(success, ErrTokenDeposit(exch, dps, valTok));
    emit EvLiquidityDeposit(exch, dps, valEth, valTok, valLiq);
    return valLiq;
  }

  function liquidityWithdrawal(uint minEth, uint minTok, uint valLiq)
    internal view returns (uint, uint) {
    (address wdr, address exch) = (msg.sender, address(this));
    uint resEth = exch.balance;
    uint resTok = token.balanceOf(exch);
    uint resLiq = totalSupply;
    require(valLiq <= resLiq, ErrLiquidityAboveTotal(exch, wdr, valLiq, resLiq));
    uint valEth = valLiq * resEth / resLiq;
    require(valEth >= minEth, ErrEtherBelowMin(exch, wdr, valEth, minEth));
    uint valTok = valLiq * resTok / resLiq;
    require(valTok >= minTok, ErrTokenBelowMin(exch, wdr, valTok, minTok));
    return (valEth, valTok);
  }

  function withdrawLiquidity(uint minEth, uint minTok, uint valLiq) external
    returns (uint, uint) {
    positive(minEth); positive(minTok); positive(valLiq);
    (address wdr, address exch) = (msg.sender, address(this));
    (uint valEth, uint valTok) = liquidityWithdrawal(minEth, minTok, valLiq);
    bool success = burn(wdr, valLiq); // Burn LIQ from the withdrawer
    require(success, ErrLiquidityBurn(exch, wdr, valLiq));
    success = token.transfer(wdr, valTok); // Deposit TOK to the withdrawer
    require(success, ErrTokenWithdraw(exch, wdr, valTok));
    (success, ) = wdr.call{value: valEth}(""); // Deposit ETH to the withdrawer
    require(success, ErrEtherWithdraw(exch, wdr, valEth));
    emit EvLiquidityWithdraw(exch, wdr, valEth, valTok, valLiq);
    return (valEth, valTok);
  }

  function inPrice(uint valIn, uint resIn, uint resOut) internal view
    returns (uint) {
    uint feeValIn = fee * valIn;
    uint valOut = feeValIn * resOut / (1000 * resIn + feeValIn);
    return valOut;
  }

  function outPrice(uint valOut, uint resIn, uint resOut) internal view
    returns (uint) {
    uint valIn = 1000 * valOut * resIn / (fee * (resOut - valOut));
    return valIn;
  }

  function inSwapToEthTok(uint minTok, address rcp) public payable
    returns (uint) {
    (address byr, address exch) = (msg.sender, address(this));
    uint valEth = msg.value;
    positive(valEth); positive(minTok); validAddress(rcp);
    uint resEth = exch.balance - valEth;
    uint resTok = token.balanceOf(exch);
    uint valTok = inPrice(valEth, resEth, resTok);
    require(valTok >= minTok, ErrTokenBelowMin(exch, byr, valTok, minTok));
    bool success = token.transfer(rcp, valTok);
    require(success, ErrTokenSwap(exch, rcp, valTok));
    emit EvTokenBuy(exch, byr, rcp, valEth, valTok);
    return valTok;
  }

  function inSwapEthTok(uint minTok) external payable returns (uint) {
    address byr = msg.sender;
    return inSwapToEthTok(minTok, byr);
  }

  function outSwapToEthTok(uint valTok, address rcp) public payable
    returns (uint) {
    (address byr, address exch) = (msg.sender, address(this));
    uint maxEth = msg.value;
    positive(maxEth); positive(valTok); validAddress(rcp);
    uint resEth = exch.balance - maxEth;
    uint resTok = token.balanceOf(exch);
    uint valEth = outPrice(valTok, resEth, resTok);
    require(valEth <= maxEth, ErrEtherAboveMax(exch, byr, valEth, maxEth));
    if (valEth < maxEth) {
      uint refEth = maxEth - valEth;
      (bool refSucc, ) = byr.call{value: refEth}("");
      require(refSucc, ErrEtherRefund(exch, byr, refEth));
      emit EvEtherRefund(exch, byr, refEth);
    }
    bool success = token.transfer(rcp, valTok);
    require(success, ErrTokenSwap(exch, rcp, valTok));
    emit EvTokenBuy(exch, byr, rcp, valEth, valTok);
    return valEth;
  }

  function outSwapEthTok(uint valTok) external payable returns (uint) {
    address byr = msg.sender;
    return outSwapToEthTok(valTok, byr);
  }

  function inSwapToTokEth(uint valTok, uint minEth, address rcp) public
    returns (uint) {
    positive(valTok); positive(minEth); validAddress(rcp);
    (address sel, address exch) = (msg.sender, address(this));
    uint resEth = exch.balance;
    uint resTok = token.balanceOf(exch);
    uint valEth = inPrice(valTok, resTok, resEth);
    require(valEth >= minEth, ErrEtherBelowMin(exch, sel, valEth, minEth));
    bool success = token.transferFrom(sel, exch, valTok);
    require(success, ErrTokenSwap(sel, exch, valTok));
    (success, ) = rcp.call{value: valEth}("");
    require(success, ErrEtherSend(exch, rcp, valEth));
    emit EvTokenSell(exch, sel, rcp, valTok, valEth);
    return valEth;
  }

  function inSwapTokEth(uint valTok, uint minEth) external returns (uint) {
    address sel = msg.sender;
    return inSwapToTokEth(valTok, minEth, sel);
  }

  function outSwapToTokEth(uint maxTok, uint valEth, address rcp) public
    returns (uint) {
    positive(maxTok); positive(valEth); validAddress(rcp);
    (address sel, address exch) = (msg.sender, address(this));
    uint resEth = exch.balance;
    uint resTok = token.balanceOf(exch);
    uint valTok = outPrice(valEth, resTok, resEth);
    require(valTok <= maxTok, ErrTokenAboveMax(exch, sel, valTok, maxTok));
    bool success = token.transferFrom(sel, exch, valTok);
    require(success, ErrTokenSwap(sel, exch, valTok));
    (success, ) = rcp.call{value: valEth}("");
    require(success, ErrEtherSend(exch, rcp, valEth));
    emit EvTokenSell(exch, sel, rcp, valTok, valEth);
    return valTok;
  }

  function outSwapTokEth(uint maxTok, uint valEth) external returns (uint) {
    address sel = msg.sender;
    return outSwapToTokEth(maxTok, valEth, sel);
  }
}
