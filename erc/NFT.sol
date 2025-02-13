// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

// ERC-721 Non-fungible token NFT standard
interface INFT {
  event Transfer(address indexed own, address indexed rcp, uint tid);
  event Approval(address indexed own, address indexed apr, uing tid);
  event ApprovalForAll(address  indexed own, address indexed opr, bool allow);

  function ownerOf(uint tid) external view returns(address own);
  function balanceOf(address own) external view returns (uint tokNum);
  function safeTransferFrom(address own, address rcp, uint tid) external payable;
  function safeTransferFrom(
    address own, address rcp, uint tid, bytes memory data
  ) external payable;
  function transferFrom(address own, address rcp, uint tid) external payable;
  function approve(address apr, uint tid) external payable;
  function getApproved(uint tid) external view returns (address apr);
  function setApprovalForAll(address opr, bool allow) external;
  function isApprovedForAll(address own, address opr)
    external view returns (bool allow);
}

interface INFTReceive {
  function onERC721Received(
    address opr, address own, uint tid, bytes memory data
  ) external returns (bytes4 sel);
}
