// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IFlashLoanEtherReceiver is ReentrancyGuard{
    function execute() external payable;
}

contract FlashLoanBank is ERC20 {
    mapping(address=>uint256) balances;
    address currUser;
    uint256 public constant FEE = 0.001 ether;

    constructor() ERC20("Flash Token", "FT") {}

    // Deposit token into the flash loan service
    function deposit() external payable{
        require(currUser!=msg.sender, "User Currently Flash Loan");
        _mint(msg.sender, msg.value * 100);
    }

    // Withdraw token from the flash loan service with interest
    function withdraw() external nonReentrant{
        require(allowance[msg.sender][address(this)]>=balanceOf(msg.sender));
        uint256 totalShare = totalSupply();
        uint256 share = balanceOf(msg.sender);
        uint256 amount = share * address(this).balance / totalShare;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success==true, "Transfer Failed");
        transferFrom(msg.sender, address(0), share);
    }

    function flashloan(uint256 amount) external {
        currUser = msg.sender;
        uint256 balanceBefore = address(this).balance;

        FlashLoanEtherReceiver(msg.sender).execute{value: address(this).balance}();

        uint256 balanceAfter = address(this).balance;

        uint256 payback;

        if(balanceOf(msg.sender)==0) payback = balanceAfter + FEE;

        require(balanceAfter>payback);

        currUser = address(this);
    }

    function getBalanceOf(address addr) external view returns(uint256) {
        uint256 balance = balanceOf(addr);
        return balance;
    }

    receive() external payable{}
}

contract NFT is ERC721 {
    
    uint256 tokenId;
    FlashLoanBank flashLoanBank;

    constructor(FlashLoanBank _flashLoanBank) ERC721("FLASH", "FL") {
        flashLoanBank = _flashLoanBank;
    }

    modifier isEOA(address addr){
        uint len;
        assembly { 
            len := extcodesize(addr) 
        }
        require(len == 0, "Not EOA Address");
        _;
    }

    function award(uint256 amount) public isEOA(msg.sender) nonReentrant{
        require(amount<5, "Maximum Amount Exceed");
        uint256 balance = flashLoanBank.getBalanceOf(msg.sender);
        require(amount*1 ether < balance, "Invalid Amount");
        for(uint256 i=0;i<amount;i++)
            _safeMint(msg.sender, ++tokenId);
    }

}







