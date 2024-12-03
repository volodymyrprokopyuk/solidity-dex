// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

abstract contract Base {
  error ErrNonPositive(uint val);
  error ErrInvalidAddress(address addr);
  error ErrUnauthorized(address addr);

  function positive(uint val) internal pure {
    require(val > 0, ErrNonPositive(val));
  }

  function validAddress(address addr) internal view {
    require(addr != address(0), ErrInvalidAddress(addr));
    require(addr != address(this), ErrInvalidAddress(addr));
  }

  function only(address addr) internal view {
    require(msg.sender == addr, ErrUnauthorized(addr));
  }
}
