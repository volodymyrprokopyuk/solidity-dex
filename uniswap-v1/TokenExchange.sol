// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Base} from "util/Base.sol";
import {IFungibleToken, FungibleToken} from "erc/FungibleToken.sol";

contract TokenExchange is Base, FungibleToken {
  address public factory;
  IFungibleToken public token;
  uint fee; // 1000 - feePermille

  event EvLiquidityDeposit(
    address indexed exch, address indexed dps, uint eth, uint tok, uint liq
  );
  event EvLiquidityWithdrawal(
    address indexed exch, address indexed wdr, uint eth, uint tok, uint liq
  );
  event EvSwapEthTok(
    address indexed exch, address indexed byr, address indexed rcp,
    uint eth, uint tok
  );

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
  // Token swap
  error ErrTokenSwap(address exch, address rcp, uint valTok);

  constructor(address tok, uint feePermille)
    FungibleToken(msg.sender, 0, "Liquidity token", "LIQ", 0)
    validAddress(address(tok)) {
    factory = msg.sender;
    token = IFungibleToken(tok);
    fee = 1000 - feePermille;
  }

  function liquidityDeposit(uint maxTok, uint minLiq) internal view
    returns (uint, uint) {
    (address dps, address exch) = (msg.sender, address(this));
    uint valEth = msg.value;
    // Current reserves
    uint resEth = exch.balance - valEth;
    uint resTok = token.balanceOf(exch);
    uint resLiq = totalSupply;
    // Actual values
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
    positive(msg.value) positive(maxTok) positive(minLiq)
    returns (uint) {
    (address dps, address exch) = (msg.sender, address(this));
    uint valEth = msg.value; // ETH already deposited for the exchange
    (uint valTok, uint valLiq) = liquidityDeposit(maxTok, minLiq);
    bool success = mint(dps, valLiq); // Mint LIQ for the depositor
    require(success, ErrLiquidityMint(exch, dps, valLiq));
    success = token.transferFrom(dps, exch, valTok); // Deposit TOK for exchange
    require(success, ErrTokenDeposit(exch, dps, valTok));
    emit EvLiquidityDeposit(exch, dps, valEth, valTok, valLiq);
    return valLiq;
  }

  function liquidityWithdrawal(uint minEth, uint minTok, uint valLiq)
    internal view
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
    return (valEth, valTok);
  }

  function withdrawLiquidity(uint minEth, uint minTok, uint valLiq) external
    positive(minEth) positive(minTok) positive(valLiq)
    returns (uint, uint) {
    (address wdr, address exch) = (msg.sender, address(this));
    (uint valEth, uint valTok) = liquidityWithdrawal(minEth, minTok, valLiq);
    bool success = burn(wdr, valLiq); // Burn LIQ from the withdrawer
    require(success, ErrLiquidityBurn(exch, wdr, valLiq));
    success = token.transfer(wdr, valTok); // Withdraw TOK from the exchange
    require(success, ErrTokenWithdraw(exch, wdr, valTok));
    (success, ) = wdr.call{value: valEth}(""); // Withdraw ETH from the exchange
    require(success, ErrEtherWithdraw(exch, wdr, valEth));
    emit EvLiquidityWithdrawal(exch, wdr, valEth, valTok, valLiq);
    return (valEth, valTok);
  }

  function inPrice(uint valIn, uint resIn, uint resOut)
    internal view
    returns (uint) {
    uint feeValIn = fee * valIn;
    uint valOut = feeValIn * resOut / (1000 * resIn + feeValIn);
    return valOut;
  }

  function outPrice(uint valOut, uint resIn, uint resOut)
    internal view
    returns (uint) {
    uint valIn = 1000 * valOut * resIn / fee * (resOut - valOut);
    return valIn;
  }

  function inSwapToEthTok(uint minTok, address rcp) public payable
    positive(msg.value) positive(minTok) validAddress(rcp)
    returns (uint) {
    (address byr, address exch) = (msg.sender, address(this));
    uint valEth = msg.value;
    uint resEth = exch.balance - valEth;
    uint resTok = token.balanceOf(exch);
    uint valTok = inPrice(valEth, resEth, resTok);
    require(valTok >= minTok, ErrTokenBelowMin(exch, byr, valTok, minTok));
    bool success = token.transfer(rcp, valTok);
    require(success, ErrTokenSwap(exch, rcp, valTok));
    emit EvSwapEthTok(exch, byr, rcp, valEth, valTok);
    return valTok;
  }

  function inSwapEthTok(uint minTok) external payable
    positive(msg.value) positive(minTok)
    returns (uint) {
    return inSwapToEthTok(minTok, msg.sender);
  }

  // inSwapEthTok Eth fixed
  // outSwapEthTok Tok fixed
}
