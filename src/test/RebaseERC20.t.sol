// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "ds-test/test.sol";
import "src/RebaseERC20.sol";

contract RebaseERC20Test is DSTest {
    RebaseERC20 rebaseERC20;

    uint256 private initial_balance;

    function setUp() public {
        rebaseERC20 = new RebaseERC20();
        initial_balance = 50 * 10**6 * 10 ** rebaseERC20.DECIMALS();
    }

    function testInit() public {
        uint256 balance = rebaseERC20.balanceOf(address(this));
        assertEq(balance, initial_balance);
    }

    function testSupplyIncrease() public {
        rebaseERC20.rebase(0, int256(rebaseERC20.totalSupply())); // Double the supply
        uint256 balance = rebaseERC20.balanceOf(address(this));
        assertEq(balance, initial_balance * 2);
    }

    function testSupplyDecrease() public {
        rebaseERC20.rebase(0, -int256(rebaseERC20.totalSupply()/2) ); // Half the supply
        uint256 balance = rebaseERC20.balanceOf(address(this));
        assertEq(balance, initial_balance / 2);
    }

    function testSendingTokens() public {
        rebaseERC20.rebase(0, int256(rebaseERC20.totalSupply())); // Double the supply

        rebaseERC20.transfer(address(0x1), rebaseERC20.totalSupply()/2);

        uint256 balanceSender = rebaseERC20.balanceOf(address(this)); // Sender now holds 50% of supply
        uint256 balanceReceiver = rebaseERC20.balanceOf(address(0x1)); // Revceiver now holds 50% of supply
        assertEq(balanceSender, rebaseERC20.totalSupply()/2);
        assertEq(balanceReceiver, rebaseERC20.totalSupply()/2);
        assertEq(rebaseERC20.totalSupply(), initial_balance * 2);
    }

    function testRebaseAfterTokenSend() public {
        rebaseERC20.rebase(0, int256(rebaseERC20.totalSupply())); // Double the supply

        rebaseERC20.transfer(address(0x1), initial_balance);

        uint256 balanceSender = rebaseERC20.balanceOf(address(this)); // Sender now holds 50% of supply
        uint256 balanceReceiver = rebaseERC20.balanceOf(address(0x1)); // Revceiver now holds 50% of supply
        assertEq(balanceSender, rebaseERC20.totalSupply()/2);
        assertEq(balanceReceiver, rebaseERC20.totalSupply()/2);
        assertEq(rebaseERC20.totalSupply(), initial_balance * 2);

        rebaseERC20.rebase(0, int256(rebaseERC20.totalSupply())); // Double the supply

        balanceSender = rebaseERC20.balanceOf(address(this)); // Sender now holds 50% of supply
        balanceReceiver = rebaseERC20.balanceOf(address(0x1)); // Revceiver now holds 50% of supply
        assertEq(balanceSender, rebaseERC20.totalSupply()/2);
        assertEq(balanceReceiver, rebaseERC20.totalSupply()/2);
        assertEq(rebaseERC20.totalSupply(), initial_balance * 4);

    }
}
