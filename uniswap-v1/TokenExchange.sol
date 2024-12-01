// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Base} from "util/Base.sol";
import {IFungibleToken, FungibleToken} from "erc/FungibleToken.sol";

contract TokenExchange is Base, FungibleToken {
  address public factory;
  IFungibleToken public token;

  event EvLiquidityDeposit(
    address indexed exch, address indexed dps, uint eth, uint tok, uint liq
  );

  // Deposit liquidity
  error ErrTokenAboveMax(address exch, address dps, uint val, uint max);
  error ErrLiquidityBelowMin(address exch, address dps, uint val, uint min);
  // Withdraw liquidity
  error ErrLiquidityAboveTotal(address exch, address wdr, uint val, uint tot);
  error ErrEtherBelowMin(address exch, address wdr, uint val, uint min);
  error ErrTokenBelowMin(address exch, address wdr, uint val, uint min);
  // Value transfer
  error ErrLiquidityMint(address exch, address dps, uint val);
  error ErrTokenDeposit(address exch, address dps, uint val);
  error ErrLiquidityBurn(address exch, address wdr, uint val);
  error ErrTokenWithdraw(address exch, address wdr, uint val);
  error ErrEtherWithdraw(address exch, address wdr, uint val);

  constructor(address tok)
    FungibleToken(msg.sender, 0, "Liquidity token", "LIQ", 0)
    validAddress(address(tok)) {
    factory = msg.sender;
    token = IFungibleToken(tok);
  }

  function depositLiquidity(uint maxTok, uint minLiq) external payable
    // positive(msg.value) positive(maxTok) positive(minLiq)
    returns (uint) {

    require(msg.value > 0);
    require(maxTok > 0);
    require(minLiq > 0);

    (address dps, address exch) = (msg.sender, address(this));
    uint valEth = msg.value;
    // Current reserves
    uint resEth = exch.balance - valEth;
    uint resTok = token.balanceOf(exch);
    uint resLiq = totalSupply;
    // Actual values
    uint valTok;
    uint valLiq;
    if (resLiq == 0) { // The first depositor
      valTok = maxTok;
      valLiq = valEth;
    } else {
      valTok = valEth * resTok / resEth;
      require(valTok <= maxTok, ErrTokenAboveMax(exch, dps, valTok, maxTok));
      valLiq = valEth * resLiq / resEth;
      require(valLiq >= minLiq, ErrLiquidityBelowMin(exch, dps, valLiq, minLiq));
    }
    bool success = mint(dps, valLiq); // Mint LIQ for dps
    require(success, ErrLiquidityMint(exch, dps, valLiq));
    success = token.transferFrom(dps, exch, valTok); // Deposit TOK for exch
    require(success, ErrTokenDeposit(exch, dps, valTok));
    emit EvLiquidityDeposit(exch, dps, valEth, valTok, valLiq);
    return valLiq;
  }

  function withdrawLiquidity(uint minEth, uint minTok, uint valLiq) external
    // positive(minEth) positive(minTok) positive(valLiq)
    returns (uint, uint) {
    (address wdr, address exch) = (msg.sender, address(this));
    // Current reserves
    uint resEth = exch.balance;
    uint resTok = token.balanceOf(exch);
    uint resLiq = totalSupply;
    require(valLiq <= resLiq, ErrLiquidityAboveTotal(exch, wdr, valLiq, resLiq));
    // Actual values
    uint valEth = valLiq * resEth / resLiq;
    require(valEth >= minEth, ErrEtherBelowMin(exch, wdr, valEth, minEth));
    uint valTok = valLiq * resTok / resLiq;
    require(valTok >= minTok, ErrTokenBelowMin(exch, wdr, valTok, minTok));
    bool success = burn(wdr, valLiq); // Burn LIQ from wdr
    require(success, ErrLiquidityBurn(exch, wdr, valLiq));
    success = token.transfer(wdr, valTok); // Withdraw TOK for wdr
    require(success, ErrTokenWithdraw(exch, wdr, valTok));
    (success, ) = wdr.call{value: valEth}(""); // Withdraw ETH for wdr
    require(success, ErrEtherWithdraw(exch, wdr, valEth));
    return (valEth, valTok);
  }
}
