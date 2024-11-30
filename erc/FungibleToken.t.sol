// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {IFungibleToken, FungibleToken} from "erc/FungibleToken.sol";

contract Token is FungibleToken {
  constructor(
    address own, uint initSupp, string memory nam, string memory sym, uint8 dec
  ) FungibleToken(own, initSupp, nam, sym, dec) { }

  function mintTokens(address rcp, uint val) external returns (bool succ) {
    return mint(rcp, val);
  }

  function burnTokens(address own, uint val) external returns (bool succ) {
    return burn(own, val);
  }
}

contract FungibleTokenTest is Test {
  address own;
  uint initSupp = 10;
  Token tok;
  address rcp;
  address spn;

  function setUp() public {
    // Create the Token contract
    own = makeAddr("own");
    tok = new Token(own, initSupp, "Token", "TOK", 0);
    assertEq(tok.totalSupply(), initSupp);
    assertEq(tok.balanceOf(own), initSupp);
    // Create the recipient and the spender
    (rcp, spn) = (makeAddr("recipient"), makeAddr("spender"));
  }

  function testTransfer() public {
    // The owner transfers tokens to the recipient
    uint val = 1;
    vm.expectEmit(true, true, false, true);
    emit IFungibleToken.Transfer(own, rcp, val);
    vm.prank(own);
    tok.transfer(rcp, val);
    assertEq(tok.balanceOf(own), initSupp - val);
    assertEq(tok.balanceOf(rcp), val);
  }

  function testTransferErrInsufficientFunds() public {
    // The owner fails to transfer more tokens than the owner owns
    uint val = initSupp + 1;
    bytes memory err = abi.encodeWithSelector(
      FungibleToken.ErrInsufficientFunds.selector, own, val
    );
    vm.expectRevert(err);
    vm.prank(own);
    tok.transfer(rcp, val);
    assertEq(tok.balanceOf(own), initSupp);
  }

  function testApproveTransferFrom() public {
    // The owner approves the spender to transfer tokens on the owner's behalf
    uint val = 1;
    vm.expectEmit(true, true, false, true);
    emit IFungibleToken.Approval(own, spn, val);
    vm.prank(own);
    tok.approve(spn, val);
    assertEq(tok.allowance(own, spn), val);
    // The spender transfers tokens from the owner to the recipient
    vm.expectEmit(true, true, false, true);
    emit IFungibleToken.Transfer(own, rcp, val);
    vm.prank(spn);
    tok.transferFrom(own, rcp, val);
    assertEq(tok.balanceOf(own), initSupp - val);
    assertEq(tok.balanceOf(rcp), val);
    assertEq(tok.allowance(own, spn), 0);
  }

  function testApproveTransferFromErrBeyondAllowance() public {
    // The owner approves the spender to transfer tokens on the owner's behalf
    uint val = 1;
    vm.expectEmit(true, true, false, true);
    emit IFungibleToken.Approval(own, spn, val);
    vm.prank(own);
    tok.approve(spn, val);
    assertEq(tok.allowance(own, spn), val);
    // The spender fails to transfer tokens beyond the spender's allowance
    bytes memory err = abi.encodeWithSelector(
      FungibleToken.ErrBeyondAllowance.selector, own, spn, val * 2
    );
    vm.expectRevert(err);
    vm.prank(spn);
    tok.transferFrom(own, rcp, val * 2);
    assertEq(tok.balanceOf(own), initSupp);
    assertEq(tok.allowance(own, spn), val);
  }

  function testMintBurn() public {
    // The owner mints new tokens by transferring them to the recipient
    uint val = 1;
    vm.expectEmit(true, true, false, true);
    emit IFungibleToken.Transfer(address(0), rcp, val);
    vm.prank(own);
    tok.mintTokens(rcp, val);
    assertEq(tok.balanceOf(rcp), val);
    assertEq(tok.totalSupply(), initSupp + val);
    // The owner burns existing tokens by withdrawing them from the recipient
    vm.expectEmit(true, true, false, true);
    emit IFungibleToken.Transfer(rcp, address(0), val);
    vm.prank(own);
    tok.burnTokens(rcp, val);
    assertEq(tok.balanceOf(rcp), 0);
    assertEq(tok.totalSupply(), initSupp);
  }

  function testMintBurnErrInsufficientFunds() public {
    // The owner mints new tokens by transferring them to the recipient
    uint val = 1;
    vm.expectEmit(true, true, false, true);
    emit IFungibleToken.Transfer(address(0), rcp, val);
    vm.prank(own);
    tok.mintTokens(rcp, val);
    assertEq(tok.balanceOf(rcp), val);
    assertEq(tok.totalSupply(), initSupp + val);
    // The owner fails to burn more tokens than the recipient owns
    bytes memory err = abi.encodeWithSelector(
      FungibleToken.ErrInsufficientFunds.selector, rcp, val * 2
    );
    vm.expectRevert(err);
    vm.prank(own);
    tok.burnTokens(rcp, val * 2);
    assertEq(tok.balanceOf(rcp), val);
    assertEq(tok.totalSupply(), initSupp + val);
  }
}
