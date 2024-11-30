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
  address public owner;
  string public name;
  string public symbol;
  uint8 public decimals;

  uint public totalSupply;
  mapping(address own => uint bal) public balanceOf;
  mapping(address own => mapping(address spn => uint maxVal)) public allowance;

  error ErrInsufficientFunds(address own, uint val);
  error ErrBeyondAllowance(address own, address spn, uint val);

  modifier sufficientFunds(address own, uint val) {
    require(balanceOf[own] >= val, ErrInsufficientFunds(own, val));
    _;
  }

  modifier withinAllowance(address own, address spn, uint val) {
    require(allowance[own][spn] >= val, ErrBeyondAllowance(own, spn, val));
    _;
  }

  constructor(
    address own, uint initSupp, string memory nam, string memory sym, uint8 dec
  ) {
    (owner, name, symbol, decimals) = (own, nam, sym, dec);
    balanceOf[own] = initSupp;
    totalSupply = initSupp;
  }

  function transfer(address rcp, uint val) external
    validAddress(rcp) sufficientFunds(msg.sender, val)
    returns (bool succ) {
    address own = msg.sender;
    balanceOf[own] -= val;
    balanceOf[rcp] += val;
    emit Transfer(own, rcp, val);
    return true;
  }

  function approve(address spn, uint maxVal) external
    validAddress(spn) sufficientFunds(msg.sender, maxVal)
    returns (bool succ) {
    address own = msg.sender;
    allowance[own][spn] = maxVal;
    emit Approval(own, spn, maxVal);
    return true;
  }

  function transferFrom(address own, address rcp, uint val) external
    validAddress(own) validAddress(rcp) withinAllowance(own, msg.sender, val)
    sufficientFunds(own, val)
    returns (bool succ) {
    address spn = msg.sender;
    allowance[own][spn] -= val;
    balanceOf[own] -= val;
    balanceOf[rcp] += val;
    emit Transfer(own, rcp, val);
    return true;
  }

  function mint(address rcp, uint val) internal
    validAddress(rcp) only(owner)
    returns (bool succ) {
    balanceOf[rcp] += val;
    totalSupply += val;
    emit Transfer(address(0), rcp, val);
    return true;
  }

  function burn(address own, uint val) internal
    only(owner) sufficientFunds(own, val)
    returns (bool succ) {
    balanceOf[own] -= val;
    totalSupply -= val;
    emit Transfer(own, address(0), val);
    return true;
  }
}
