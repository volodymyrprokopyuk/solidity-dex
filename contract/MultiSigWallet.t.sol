// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.28;

import {Test} from "std/Test.sol";
import {Base} from "util/Base.sol";
import {MultiSigWallet} from "contract/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
  MultiSigWallet wallet;
  address own1;
  address own2;
  address own3;
  address rcp; // recipient

  function setUp() public {
    // Create three owners and a recipient
    (own1, own2, own3) = (makeAddr("own1"), makeAddr("own2"), makeAddr("own3"));
    rcp = makeAddr("rcp");
    // Create a MultiSigWallet contract
    address[] memory owners = new address[](3);
    owners[0] = own1; owners[1] = own2; owners[2] = own3;
    wallet = new MultiSigWallet(owners, 2);
  }

  function testProposeApproveRevokeExecuteTx() public {
    uint value = 1 ether;
    uint tid = 0;
    // A transaction proposal fails if the wallet have insufficient funds
    bytes memory err = abi.encodeWithSelector(
      MultiSigWallet.ErrWalletInsufficientFunds.selector, value
    );
    vm.expectRevert(err, address(wallet));
    vm.prank(own1);
    wallet.proposeTx(rcp, value);
    // An owner proposes a transaction if the wallet have sufficient funds
    vm.deal(address(wallet), value);
    vm.expectEmit(true, true, false, true, address(wallet));
    emit MultiSigWallet.EvTxPropose(tid, rcp, value);
    vm.prank(own1);
    wallet.proposeTx(rcp, value);
    // An owner approves the proposed transaction
    vm.expectEmit(true, true, false, false, address(wallet));
    emit MultiSigWallet.EvTxApprove(tid, own1);
    vm.prank(own1);
    wallet.approveTx(tid);
    // A recipient, being not an owner, fails to approve the proposed transaction
    err = abi.encodeWithSelector(
      Base.ErrUnauthorized.selector, rcp
    );
    vm.expectRevert(err, address(wallet));
    vm.prank(rcp);
    wallet.approveTx(tid);
    // The transaction with not enough approvals fails to execute
    err = abi.encodeWithSelector(
      MultiSigWallet.ErrTxNotApproved.selector, tid, address(0)
    );
    vm.expectRevert(err, address(wallet));
    vm.prank(own3);
    wallet.executeTx(tid);
    // The owner that already approved the transaction fails to approve it again
    err = abi.encodeWithSelector(
      MultiSigWallet.ErrTxApproved.selector, tid, own1
    );
    vm.expectRevert(err, address(wallet));
    vm.prank(own1);
    wallet.approveTx(tid);
    // Another owner approves the proposed transaction
    vm.expectEmit(true, true, false, false, address(wallet));
    emit MultiSigWallet.EvTxApprove(tid, own2);
    vm.prank(own2);
    wallet.approveTx(tid);
    // An owner executes the approved transaction
    vm.expectEmit(true, true, false, false, address(wallet));
    emit MultiSigWallet.EvTxExecute(tid, own3);
    vm.prank(own3);
    wallet.executeTx(tid);
  }
}
