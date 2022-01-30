// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.4;

// import "ds-test/test.sol";
// import "src/RebaseERC20WithMint.sol";

// contract RebaseERC20WithMintTest is DSTest {
//     RebaseERC20WithMint rebaseERC20WithMint;

//     function setUp() public {
//         rebaseERC20WithMint = new RebaseERC20WithMint();
//     }

//     function testInit() public {
//         uint256 balance = rebaseERC20WithMint.balanceOf(address(this));
//         assertEq(balance, 1);
//     }

//     function testMint() public {
//         rebaseERC20WithMint.mint(address(this), 1);
//         // uint256 balance = rebaseERC20WithMint.balanceOf(address(this));
//         // assertEq(balance, 2);
//     }

// }
