// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

contract FlashLoanBank is ERC20, ReentrancyGuard {
    // The user currently using the flash loan service
    address internal user;
    // The balance user deposit into the flash loan service
    mapping(address=>uint256) balances;
    // The fee paid to each flash loan request
    uint256 public constant FEE = 0.001 ether;

    constructor() ERC20("Flash Token", "FT") {}

    // Deposit token into the flash loan service
    function deposit() external payable{
        require(user!=msg.sender, "User Currently Flash Loan"); // Security Check
        _mint(msg.sender, msg.value * 100); // Mint share token to user, 1 ether deposit get 100x share token
    }

    // Withdraw token from the flash loan service with interest
    function withdraw() external nonReentrant{
        // An user can get the ether corresponding to the ratio of his/her share of totalSupply()
        // If an user have 10% share token and the flash loan service has 100 ether locked
        // The user get 100 * 10% = 10 ether back
        uint256 totalShare = totalSupply();
        uint256 share = balanceOf(msg.sender);
        uint256 amount = share * address(this).balance / totalShare;
    
        // Transfer Ether
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer Failed");
        
        // Transfer share token to this address
        transfer(address(this), share);
    }

    // Simple flash loan service that user with more that 100 share tokens does not need to pay fee
    function flashloan() external {
        user = msg.sender;

        uint256 balanceBefore = address(this).balance;

        IFlashLoanEtherReceiver(msg.sender).execute{value: address(this).balance}();

        uint256 balanceAfter = address(this).balance;

        uint256 payback = balanceBefore;

        // If user has more than 100 share token, he/she does not need to pay the fee
        if(balanceOf(msg.sender) < 1e20) payback = balanceBefore + FEE;

        require(balanceAfter>payback, "Flash Loan Failed");

        user = address(this);
    }

    // Get current share token balance
    function getBalanceOf(address addr) external view returns(uint256) {
        uint256 balance = balanceOf(addr);
        return balance;
    }

    receive() external payable{}
}

contract NFT is ERC721, ReentrancyGuard{

    FlashLoanBank flashLoanBank;
    
    uint256 public tokenId;

    constructor(FlashLoanBank _flashLoanBank) ERC721("FLASH", "FL") {
        flashLoanBank = _flashLoanBank;
    }

    // User with share token can buy valuable FLASH NFT
    // One single purchase is limited to 5 NFTs
    // Each 100 share token an user owns allows he/she to buy 1 NFT
    // Each NFT requires 1 ether
    function award(uint256 amount) public payable nonReentrant{
        require(amount<=5, "Maximum Amount Exceed"); // Maximum purchase amount within single transaction is 5
        // Ensure an user has enough share token
        uint256 balance = flashLoanBank.getBalanceOf(msg.sender);
        require(amount*1e20 <= balance, "Invalid Amount");
        // Ensure user transfer enough ethers
        require(msg.value>=amount*1 ether);
        // Mint NFT to user with amount
        for(uint256 i=0;i<amount;i++)
            _safeMint(msg.sender, ++tokenId);
    }
}







