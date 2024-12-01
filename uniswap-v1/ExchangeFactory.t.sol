// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {ExchangeFactory} from "uniswap-v1/ExchangeFactory.sol";

contract ExchangeFactoryTest is Test {
  ExchangeFactory internal reg;

  function setUp() public {
    reg = new ExchangeFactory();
  }

  function testExchanges() public view {
    assertEq(reg.exchanges(), 0);
  }
}
