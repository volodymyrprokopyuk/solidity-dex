// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

// ERC-20 Token standard
interface IFungibleToken {
  event Transfer(address indexed own, address indexed rcp, uint val);
  event Approval(address indexed own, address indexed spn, uint maxVal);

  function totalSupply() external view returns (uint totSupp);
  function balanceOf(address own) external view (uint bal);
  function transfer(address rcp, uint val) external returns (bool succ);
  function approve(address spn, uint maxVal) external returns (bool succ);
  function allowance(address own, address spn)
    external view returns (uint remVal);
  function transferFrom(address own, address rcp, uint val)
    external view returns (bool succ);
}

contract FungibleToken is IFungibleToken {
  string public name;
  string public symbol;
  uint8 public decimals;
}
