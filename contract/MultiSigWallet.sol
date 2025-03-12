// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Base} from "util/Base.sol";

contract MultiSigWallet is Base {
  struct Tx {
    address recipient;
    uint value;
    bool executed;
  }

  event EvReceive(address indexed sender, uint value);
  event EvTxPropose(uint indexed tid, address indexed recipient, uint val);
  event EvTxApprove(uint indexed tid, address indexed approver);
  event EvTxRevoke(uint indexed tid, address indexed revoker);
  event EvTxExecute(uint indexed tid, address indexed executor);

  error ErrOwnerBelowMin(uint currOwners, uint minOwners);
  error ErrOwnerAlready(address owner);
  error ErrWalletInsufficientFunds(uint value);
  error ErrTxInvalid(uint tid);
  error ErrTxExecuted(uint tid);
  error ErrTxApproved(uint tid, address approver);
  error ErrTxNotApproved(uint tid, address revoker);
  error ErrTxExecute(uint tid, address executor);

  address[] owners;
  mapping(address addr => bool owner) isOwner;
  uint minApprovals;
  Tx[] txs;
  mapping(uint tid => address[] approvals) txApprovals;

  function onlyOwners(address sender) internal view {
    require(isOwner[sender], ErrUnauthorized(sender));
  }

  function sufficientFunds(uint value) internal view {
    require(address(this).balance >= value, ErrWalletInsufficientFunds(value));
  }

  function txValid(uint tid) internal view {
    require(tid < txs.length, ErrTxInvalid(tid));
    require(!txs[tid].executed, ErrTxExecuted(tid));
  }

  function txApproved(uint tid) internal view {
    require(
      txApprovals[tid].length >= minApprovals, ErrTxNotApproved(tid, address(0))
    );
  }

  constructor(address[] memory owns, uint minAprs) {
    positive(minAprs);
    minApprovals = minAprs;
    require(owns.length >= minAprs, ErrOwnerBelowMin(owns.length, minAprs));
    for (uint i = 0; i < owns.length; i++) {
      address owner = owns[i];
      validAddress(owner);
      require(!isOwner[owner], ErrOwnerAlready(owner));
      owners.push(owner);
      isOwner[owner] = true;
    }
  }

  receive() external payable {
    emit EvReceive(msg.sender, msg.value);
  }

  function proposeTx(address recipient, uint value) external {
    address proposer = msg.sender;
    onlyOwners(proposer);
    validAddress(recipient);
    sufficientFunds(value);
    uint tid = txs.length;
    Tx memory txn = Tx({recipient: recipient, value: value, executed: false});
    txs.push(txn);
    emit EvTxPropose(tid, recipient, value);
  }

  function approveTx(uint tid) external {
    address approver = msg.sender;
    onlyOwners(approver);
    txValid(tid);
    sufficientFunds(txs[tid].value);
    address[] storage approvals = txApprovals[tid];
    for (uint i = 0; i < approvals.length; i++) {
      address approval = approvals[i];
      require(approval != approver, ErrTxApproved(tid, approver));
    }
    approvals.push(approver);
    emit EvTxApprove(tid, approver);
  }

  function revokeApproval(uint tid) external {
    address revoker = msg.sender;
    onlyOwners(revoker);
    txValid(tid);
    address[] storage approvals = txApprovals[tid];
    for (uint i = 0; i < approvals.length; i++) {
      address approval = approvals[i];
      if (approval == revoker) {
        approvals[i] = approvals[approvals.length - 1];
        approvals.pop();
        emit EvTxRevoke(tid, revoker);
        return;
      }
    }
    revert ErrTxNotApproved(tid, revoker);
  }

  function executeTx(uint tid) external {
    address executor = msg.sender;
    onlyOwners(executor);
    txValid(tid);
    txApproved(tid);
    sufficientFunds(txs[tid].value);
    Tx storage txn = txs[tid];
    txn.executed = true;
    (bool succ, ) = txn.recipient.call{value: txn.value}("");
    require(succ, ErrTxExecute(tid, executor));
    emit EvTxExecute(tid, executor);
  }
}
