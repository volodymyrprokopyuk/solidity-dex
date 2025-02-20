// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Base} from "util/Base.sol";

// ERC-721 Non-fungible token NFT standard
interface INFT {
  event Transfer(address indexed own, address indexed rcp, uint tid);
  event Approval(address indexed own, address indexed apr, uint tid);
  event ApprovalForAll(address  indexed own, address indexed opr, bool allow);

  function ownerOf(uint tid) external view returns(address own);
  function balanceOf(address own) external view returns (uint tokNum);
  function transferFrom(address own, address rcp, uint tid) external payable;
  function safeTransferFrom(
    address own, address rcp, uint tid, bytes memory data
  ) external payable;
  function safeTransferFrom(address own, address rcp, uint tid) external payable;
  function approve(address apr, uint tid) external;
  function getApproved(uint tid) external view returns (address apr);
  function setApprovalForAll(address opr, bool allow) external;
  function isApprovedForAll(address own, address opr)
    external view returns (bool allow);
}

interface INFTRecipient {
  function onERC721Received(
    address opr, address own, uint tid, bytes memory data
  ) external returns (bytes4 sel);
}

abstract contract NFT is INFT, Base {
  address minter;
  public mapping(uint tid => address own) ownerOf;
  public mapping(address own => uint tokNum) balanceOf;
  public mapping(uint tid => address apr) getApproved;
  public mapping(address own =>
    mapping(address opr => bool allow)) isApprovedForAll;

  error ErrNFTAlreadyExists(uint tid);
  error ErrNFTNotExist(uint tid);
  error ErrUnauthorizedTransfer(address snd, uint tid);
  error ErrNFTReceive(address own, address rcp, uint tid);
  error ErrUnauthorizedApprove(address snd, uint tid);
  error ErrNothingToApprove(address own, address opr);

  constructor(address mnt) {
    minter = mnt;
  }

  function newNFT(uint tid) internal view {
    require(ownerOf(tid) == address(0), ErrNFTAlreadyExists(tid))
  }

  function validNFT(uint tid) internal view {
    require(ownerOf(tid) != address(0), ErrNFTNotExist(tid))
  }

  function ownerOrApprovedOrOperator(uint tid) internal view {
    address own = ownerOf(tid);
    address apr = getApproved(tid);
    address opr = msg.sender;
    bool allow = isApprovedForAll(own, opr);
    require(
      own == msg.sender || apr == msg.sender || allow,
      ErrUnauthorizedTransfer(msg.sender, tid)
    );
  }

  function ownerOrOperator(uint tid) internal view {
    address own = ownerOf(tid);
    address opr = msg.sender;
    bool allow = isApprovedForAll(own, opr)
    require(own == msg.sender || allow, ErrUnauthorizedApprove(msg.sender, tid));
  }

  function mint(address rcp, uint tid) internal {
    only(minter);
    validAddress(rcp);
    newNFT(tid);
    ownerOf[tid] = rcp;
    balanceOf[rcp]++;
    emit Transfer(address(0), rcp, tid)
  }

  function burn(uint tid) internal {
    only(minter);
    validNFT(tid);
    address own = ownerOf(tid);
    delete ownerOf[tid];
    balanceOf[own]--;
    emit Transfer(own, address(0), tid)
  }

  function transferFrom(address own, address rcp, uint tid) public payable {
    ownerOrApprovedOrOperator(tid);
    validNFT(tid);
    validAddress(rcp);
    delete ownerOf[tid];
    balanceOf[own]--;
    ownerOf[tid] = rcp;
    balanceOf[rcp]++;
  }

  function safeTransferFrom(
    address own, address rcp, uint tid, bytes memory data
  ) external payable {
    transferFrom(own, rcp, tid);
    if (rcp.code.length > 0) {
      bytes4 received = INFTRecipient(rcp).onERC721Received(
        msg.sender, own, tid, data
      );
      require(
        received == INFTRecipient.onERC721Received.selector,
        ErrNFTReceive(own, rcp, tid)
      );
    }
    emit Transfer(own, rcp, tid);
  }

  function safeTransferFrom(address own, address rcp, uint tid)
    external payable {
    safeTransferFrom(own, rcp, tid, "")
  }

  function approve(address apr, uint tid) external {
    ownerOrOperator(tid);
    validNFT(tid);
    validAddress(apr);
    getApproved[tid] = apr;
    emit Approval(msg.sender, apr, tid);
  }

  function setApprovalForAll(address opr, bool allow) external {
    if (allow) {
      address own = msg.sender;
      require(balanceOf(own) > 0, ErrNothingToApprove(own, opr));
      ApprovalForAll[own][opr] = allow
    } else {
      delete ApprovalForAll[own][opr]
    }
  }
}

contract NFToken is NFT {
  constructor(address mnt) NFT(mnt) {}

  function mintNFT(address rcp, uint tid) external {
    mint(rcp, tid)
  }

  function burnNFT(uint tid) external {
    burn(tid)
  }
}
