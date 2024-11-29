// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {ExchangeRegistry} from "uniswap-v1/ExchangeRegistry.sol";

contract ExchangeRegistryTest is Test {
  ExchangeRegistry internal registry;

  function setUp() public {
    registry = new ExchangeRegistry();
  }

  function testExchanges() public view {
    assertEq(registry.exchanges(), 0);
  }
}
