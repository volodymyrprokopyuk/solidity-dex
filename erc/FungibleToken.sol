// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Base} from "util/Base.sol";

// ERC-20 Token standard
interface IFungibleToken {
  event Transfer(address indexed own, address indexed rcp, uint val);
  event Approval(address indexed own, address indexed spn, uint maxVal);

  function totalSupply() external view returns (uint totSupp);
  function balanceOf(address own) external view returns (uint bal);
  function transfer(address rcp, uint val) external returns (bool succ);
  function approve(address spn, uint maxVal) external returns (bool succ);
  function allowance(address own, address spn) external view
    returns (uint remVal);
  function transferFrom(address own, address rcp, uint val) external
    returns (bool succ);
}

abstract contract FungibleToken is IFungibleToken, Base {
  string public name;
  string public symbol;
  uint8 public decimals;

  uint public totalSupply;
  mapping(address own => uint bal) public balanceOf;
  mapping(address own => mapping(address spn => uint remVal)) public allowance;

  error ErrInsufficientFunds(address own, uint val);
  error ErrBeyondAllowance(address own, address spn, uint val);

  function sufficientFunds(address own, uint val) internal view {
    require(balanceOf[own] >= val, ErrInsufficientFunds(own, val));
  }

  function withinAllowance(address own, address spn, uint val) internal view {
    require(allowance[own][spn] >= val, ErrBeyondAllowance(own, spn, val));
  }

  constructor(string memory nam, string memory sym, uint8 dec) {
    (name, symbol, decimals) = (nam, sym, dec);
  }

  function transfer(address rcp, uint val) external returns (bool) {
    address own = msg.sender;
    validAddress(rcp);
    sufficientFunds(own, val);
    balanceOf[own] -= val;
    balanceOf[rcp] += val;
    emit Transfer(own, rcp, val);
    return true;
  }

  function approve(address spn, uint maxVal) external returns (bool) {
    address own = msg.sender;
    validAddress(spn);
    sufficientFunds(own, maxVal);
    allowance[own][spn] = maxVal;
    emit Approval(own, spn, maxVal);
    return true;
  }

  function transferFrom(address own, address rcp, uint val) external
    returns (bool) {
    address spn = msg.sender;
    validAddress(own);
    validAddress(rcp);
    withinAllowance(own, spn, val);
    sufficientFunds(own, val);
    allowance[own][spn] -= val;
    balanceOf[own] -= val;
    balanceOf[rcp] += val;
    emit Transfer(own, rcp, val);
    return true;
  }

  function mint(address rcp, uint val) internal returns (bool) {
    validAddress(rcp);
    balanceOf[rcp] += val;
    totalSupply += val;
    emit Transfer(address(0), rcp, val);
    return true;
  }

  function burn(address own, uint val) internal returns (bool) {
    sufficientFunds(own, val);
    balanceOf[own] -= val;
    totalSupply -= val;
    emit Transfer(own, address(0), val);
    return true;
  }
}

contract Token is FungibleToken {
  constructor(string memory nam, string memory sym, uint8 dec)
    FungibleToken(nam, sym, dec) {}

  function mintTokens(address rcp, uint val) external returns (bool) {
    return mint(rcp, val);
  }

  function burnTokens(address own, uint val) external returns (bool) {
    return burn(own, val);
  }
}
