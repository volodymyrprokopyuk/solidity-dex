// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {console} from "std/console.sol";
import {Script} from "std/Script.sol";
import {Token} from "erc/FungibleToken.sol";

contract FungibleTokenScript is Script {
  function run() external {
    uint dplPrv = vm.envUint("DPL_PRV");
    vm.startBroadcast(dplPrv);
    Token token = new Token("Token", "TOK", 0);
    vm.stopBroadcast();
    console.log("Contract %s", address(token));
  }
}
