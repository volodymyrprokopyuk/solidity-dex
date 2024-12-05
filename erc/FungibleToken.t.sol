// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {IFungibleToken, FungibleToken} from "erc/FungibleToken.sol";

contract Token is FungibleToken {
  constructor(string memory nam, string memory sym, uint8 dec)
    FungibleToken(nam, sym, dec) { }

  function mintTokens(address rcp, uint val) external returns (bool) {
    return mint(rcp, val);
  }

  function burnTokens(address own, uint val) external returns (bool) {
    return burn(own, val);
  }
}

contract FungibleTokenTest is Test {
  address owner;
  uint supply = 10;
  Token token;
  address rcp; // recipient
  address spn; // spender

  function setUp() public {
    // Create the Token contract
    owner = makeAddr("owner");
    token = new Token("Token", "TOK", 0);
    token.mintTokens(owner, supply);
    assertEq(token.totalSupply(), supply);
    assertEq(token.balanceOf(owner), supply);
    // Create the recipient and the spender
    (rcp, spn) = (makeAddr("recipient"), makeAddr("spender"));
  }

  function testTransfer() public {
    // The owner transfers tokens to the recipient
    uint val = 1;
    vm.expectEmit(true, true, false, true);
    emit IFungibleToken.Transfer(owner, rcp, val);
    vm.prank(owner);
    token.transfer(rcp, val);
    assertEq(token.balanceOf(owner), supply - val);
    assertEq(token.balanceOf(rcp), val);
  }

  function testTransferErrInsufficientFunds() public {
    // The owner fails to transfer more tokens than the owner owns
    uint val = supply + 1;
    bytes memory err = abi.encodeWithSelector(
      FungibleToken.ErrInsufficientFunds.selector, owner, val
    );
    vm.expectRevert(err);
    vm.prank(owner);
    token.transfer(rcp, val);
    assertEq(token.balanceOf(owner), supply);
  }

  function testApproveTransferFrom() public {
    // The owner approves the spender to transfer tokens on the owner's behalf
    uint val = 1;
    vm.expectEmit(true, true, false, true);
    emit IFungibleToken.Approval(owner, spn, val);
    vm.prank(owner);
    token.approve(spn, val);
    assertEq(token.allowance(owner, spn), val);
    // The spender transfers tokens from the owner to the recipient
    vm.expectEmit(true, true, false, true);
    emit IFungibleToken.Transfer(owner, rcp, val);
    vm.prank(spn);
    token.transferFrom(owner, rcp, val);
    assertEq(token.balanceOf(owner), supply - val);
    assertEq(token.balanceOf(rcp), val);
    assertEq(token.allowance(owner, spn), 0);
  }

  function testApproveTransferFromErrBeyondAllowance() public {
    // The owner approves the spender to transfer tokens on the owner's behalf
    uint val = 1;
    vm.expectEmit(true, true, false, true);
    emit IFungibleToken.Approval(owner, spn, val);
    vm.prank(owner);
    token.approve(spn, val);
    assertEq(token.allowance(owner, spn), val);
    // The spender fails to transfer tokens beyond the spender's allowance
    bytes memory err = abi.encodeWithSelector(
      FungibleToken.ErrBeyondAllowance.selector, owner, spn, val * 2
    );
    vm.expectRevert(err);
    vm.prank(spn);
    token.transferFrom(owner, rcp, val * 2);
    assertEq(token.balanceOf(owner), supply);
    assertEq(token.allowance(owner, spn), val);
  }

  function testMintBurn() public {
    // The owner mints new tokens by transferring them to the recipient
    uint val = 1;
    vm.expectEmit(true, true, false, true);
    emit IFungibleToken.Transfer(address(0), rcp, val);
    vm.prank(owner);
    token.mintTokens(rcp, val);
    assertEq(token.balanceOf(rcp), val);
    assertEq(token.totalSupply(), supply + val);
    // The owner burns existing tokens by withdrawing them from the recipient
    vm.expectEmit(true, true, false, true);
    emit IFungibleToken.Transfer(rcp, address(0), val);
    vm.prank(owner);
    token.burnTokens(rcp, val);
    assertEq(token.balanceOf(rcp), 0);
    assertEq(token.totalSupply(), supply);
  }

  function testMintBurnErrInsufficientFunds() public {
    // The owner mints new tokens by transferring them to the recipient
    uint val = 1;
    vm.expectEmit(true, true, false, true);
    emit IFungibleToken.Transfer(address(0), rcp, val);
    vm.prank(owner);
    token.mintTokens(rcp, val);
    assertEq(token.balanceOf(rcp), val);
    assertEq(token.totalSupply(), supply + val);
    // The owner fails to burn more tokens than the recipient owns
    bytes memory err = abi.encodeWithSelector(
      FungibleToken.ErrInsufficientFunds.selector, rcp, val * 2
    );
    vm.expectRevert(err);
    vm.prank(owner);
    token.burnTokens(rcp, val * 2);
    assertEq(token.balanceOf(rcp), val);
    assertEq(token.totalSupply(), supply + val);
  }
}
