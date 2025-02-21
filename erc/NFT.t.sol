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
    minter = makeAddr("minter");
    nft = new NFToken(minter);
    (own, rcp) = (makeAddr("owner"), makeAddr("recipient"));
    (apr, opr) = (makeAddr("approved"), makeAddr("operator"));
  }

  function testSafeTransferFrom() public {
    uint tid = 1;
    vm.prank(minter);
    nft.mintNFT(own, tid);
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
    vm.expectEmit(true, true, false, true, address(nft));
    emit INFT.Approval(own, apr, tid);
    vm.prank(own);
    nft.approve(apr, tid);
    assertEq(nft.getApproved(tid), apr);
    bytes memory err = abi.encodeWithSelector(
      NFT.ErrUnauthorizedTransfer.selector, opr, tid
    );
    vm.expectRevert(err, address(nft));
    vm.prank(opr);
    nft.safeTransferFrom(own, rcp, tid);
    vm.prank(apr);
    nft.safeTransferFrom(own, rcp, tid);
    assertEq(nft.ownerOf(tid), rcp);
    assertEq(nft.balanceOf(rcp), 1);
    assertEq(nft.balanceOf(own), 0);
  }
}
