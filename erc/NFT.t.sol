// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Test} from "std/Test.sol";
import {INFT, NFT, NFToken, INFTRecipient} from "erc/NFT.sol";

contract NFTRecipient is INFTRecipient {
  function onERC721Received(address, address, uint, bytes memory)
    external pure returns (bytes4) {
    return NFTRecipient.onERC721Received.selector;
  }
}

contract NFTokenTest is Test {
  address minter;
  NFToken nft;
  address own; // owner
  address rcp; // recipient
  address apr; // approved
  address opr; // operator

  function setUp() public {
    // Create a NFT contract
    minter = makeAddr("minter");
    nft = new NFToken(minter);
    // Create an owner, a recipient, an approved address, an operator
    (own, rcp) = (makeAddr("owner"), makeAddr("recipient"));
    (apr, opr) = (makeAddr("approved"), makeAddr("operator"));
  }

  function testSafeTransferFrom() public {
    uint tid = 1;
    vm.prank(minter);
    nft.mintNFT(own, tid);
    // The owner directly transfers an NFT to a recipient EOA
    vm.expectEmit(true, true, false, true, address(nft));
    emit INFT.Transfer(own, rcp, tid);
    vm.prank(own);
    nft.safeTransferFrom(own, rcp, tid);
    assertEq(nft.ownerOf(tid), rcp);
    assertEq(nft.balanceOf(rcp), 1);
    assertEq(nft.balanceOf(own), 0);
  }

  function testSafeTransferFromContract() public {
    address ctr = address(new NFTRecipient());
    uint tid = 1;
    vm.prank(minter);
    nft.mintNFT(own, tid);
    // The owner directly transfers an NFT to a recipient contract
    vm.expectEmit(true, true, false, true, address(nft));
    emit INFT.Transfer(own, ctr, tid);
    vm.prank(own);
    nft.safeTransferFrom(own, ctr, tid);
    assertEq(nft.ownerOf(tid), ctr);
    assertEq(nft.balanceOf(ctr), 1);
    assertEq(nft.balanceOf(own), 0);
  }

  function testApproveSafeTransferFrom() public {
    uint tid = 1;
    vm.prank(minter);
    nft.mintNFT(own, tid);
    // The owner approves an approved address for a specific NFT
    vm.expectEmit(true, true, false, true, address(nft));
    emit INFT.Approval(own, apr, tid);
    vm.prank(own);
    nft.approve(apr, tid);
    assertEq(nft.getApproved(tid), apr);
    // A not approved address (opr) fails to transfer a specific NFT
    bytes memory err = abi.encodeWithSelector(
      NFT.ErrUnauthorizedTransfer.selector, opr, tid
    );
    vm.expectRevert(err, address(nft));
    vm.prank(opr);
    nft.safeTransferFrom(own, rcp, tid);
    // An approved address (apr) transfers a specific NFT from the owner to a
    // recipient
    vm.prank(apr);
    nft.safeTransferFrom(own, rcp, tid);
    assertEq(nft.ownerOf(tid), rcp);
    assertEq(nft.balanceOf(rcp), 1);
    assertEq(nft.balanceOf(own), 0);
  }

  function testSetApprovalForAllSafeTransferFrom() public {
    (uint tid1, uint tid2) = (1, 2);
    vm.startPrank(minter);
    nft.mintNFT(own, tid1);
    nft.mintNFT(own, tid2);
    vm.stopPrank();
    // The owner approves an operator to manage all owner NTFs
    bool allow = true;
    vm.expectEmit(true, true, false, true, address(nft));
    emit INFT.ApprovalForAll(own, opr, allow);
    vm.prank(own);
    nft.setApprovalForAll(opr, allow);
    assertEq(nft.isApprovedForAll(own, opr), allow);
    // The approved operator transfers a NFT from the owner to a recipient
    vm.expectEmit(true, true, false, true, address(nft));
    emit INFT.Transfer(own, rcp, tid1);
    vm.prank(opr);
    nft.safeTransferFrom(own, rcp, tid1);
    assertEq(nft.ownerOf(tid1), rcp);
    assertEq(nft.balanceOf(rcp), 1);
    assertEq(nft.balanceOf(own), 1);
    // The owner removes the approval for the operator to manage all owner NFTs
    allow = false;
    vm.expectEmit(true, true, false, true, address(nft));
    emit INFT.ApprovalForAll(own, opr, allow);
    vm.prank(own);
    nft.setApprovalForAll(opr, allow);
    assertEq(nft.isApprovedForAll(own, opr), allow);
    // A not approved operator fails to transfer an NFT
    bytes memory err = abi.encodeWithSelector(
      NFT.ErrUnauthorizedTransfer.selector, opr, tid2
    );
    vm.expectRevert(err, address(nft));
    vm.prank(opr);
    nft.safeTransferFrom(own, rcp, tid2);
    assertEq(nft.ownerOf(tid2), own);
    assertEq(nft.balanceOf(rcp), 1);
    assertEq(nft.balanceOf(own), 1);
  }
}
