// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a673994de5eba4305cefb8ae98ea9ad37a43efaa/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a673994de5eba4305cefb8ae98ea9ad37a43efaa/contracts/token/ERC20/utils/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a673994de5eba4305cefb8ae98ea9ad37a43efaa/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a673994de5eba4305cefb8ae98ea9ad37a43efaa/contracts/security/Pausable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a673994de5eba4305cefb8ae98ea9ad37a43efaa/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a673994de5eba4305cefb8ae98ea9ad37a43efaa/contracts/security/ReentrancyGuard.sol";

contract ForkedCrowdsale is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    uint256 private constant TOKEN_DECIMALS = 18;

    address public tokenContract;
    uint256 public tokenPrice;
    uint256 public preSaleTokensSold;
    uint256 public preSaleTokens;
    uint256 public minBuy;  
    uint256 public maxBuy;  
    uint256 public preSaleStartTime;
    uint256 public preSaleStopTime;
    bool private saleCreated;

    /**
     * @dev Emitted when `_numOfTokens` are bought
     */
    event Buy(address _buyer, uint256 _numOfTokens);

    /**
     * @dev Sets the values for {owner}, {tokenContract}
     */
    constructor (address _tokenContract) {
        tokenContract = _tokenContract;
    }

    /**
     * @dev Sets the values for {tokenPrice}, {preSaleTokens}, {minBuy}, {maxBuy},
     * {preSaleStartTime} and {preSaleStopTime}.
     *
     * {tokenPrice} is in Wei, {minBuy} and {maxBuy} are in Wei.
     * {preSaleStartTime} and {preSaleStopTime} are in Unix timestamp (seconds).
     * 
     * It requires transfer of presale tokens from {msg.sender} to Contract Address.
     */
    function createPreSale(
        uint256 _tokenPrice, 
        uint256 _preSaleTokens,
        uint256 _minBuy,
        uint256 _maxBuy,
        uint256 _preSaleStartTime,
        uint256 _preSaleStopTime
    ) external onlyOwner {
        tokenPrice = _tokenPrice; // 1 MATIC = 10 ** 18
        preSaleTokens = _preSaleTokens;
        minBuy = _minBuy;
        maxBuy = _maxBuy;
        preSaleStartTime = _preSaleStartTime;
        preSaleStopTime = _preSaleStopTime;
        saleCreated = true;

        IERC20(tokenContract).safeTransferFrom(msg.sender, address(this), _preSaleTokens);
    } 

    /**
     * @dev Updates Token Contract Address
     */
    function updateTokenContract(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0));
        tokenContract = _tokenContract;
    }

    /**
     * @dev Updates Price of Token (in MATIC)
     */
    function updatePrice(uint256 _newPrice) external onlyOwner {
        tokenPrice = _newPrice;
    }

    /**
     * @dev Add tokens to presale
     */
    function addPreSaleTokens(uint256 _numOfTokens) external onlyOwner {
        preSaleTokens = preSaleTokens.add(_numOfTokens);

        IERC20(tokenContract).safeTransferFrom(msg.sender, address(this), _numOfTokens);
    }

    /**
     * @dev Updates minimum buy amount
     */
    function updateMinBuy(uint256 _minBuy) external onlyOwner {
        require(_minBuy < maxBuy , "Minimum buy amount should be less than maximum buy amount");
        minBuy = _minBuy;
    }

    /**
     * @dev Updates maximum buy amount
     */
    function updateMaxBuy(uint256 _maxBuy) external onlyOwner {
        require(_maxBuy > minBuy, "Maximum buy amount should be greater than minimum buy amount");
        maxBuy = _maxBuy;
    }

    /**
     * @dev Updates presale start time (Unix Timestamp Seconds)
     */
    function updatePreSaleStartTime(uint256 _preSaleStartTime) external onlyOwner {
        require(_preSaleStartTime < preSaleStopTime, "Start time should be less than stop time");
        preSaleStartTime = _preSaleStartTime;
    }

    /**
     * @dev Updates presale stop time (Unix Timestamp Seconds)
     */
    function updatePreSaleStopTime(uint256 _preSaleStopTime) external onlyOwner {
        require(_preSaleStopTime > preSaleStartTime, "Stop time should be greater than start time");
        preSaleStopTime = _preSaleStopTime;
    }

    /**
     * @dev Calculate Price for Number of Tokens (in MATIC)
     */
    function calculatePrice(uint256 _numOfTokens) public view returns(uint256) {
        return _numOfTokens.mul(tokenPrice).div(10 ** TOKEN_DECIMALS);
    }

    /**
     * @dev Function to Buy Tokens with MATIC
     */
    function buy(uint256 _numOfTokens) external payable nonReentrant {
        require(saleCreated == true, "Sale has not created yet");
        require(preSaleTokensSold.add(_numOfTokens) <= preSaleTokens, "Exceeds Presale Token Limit");
        require(block.timestamp >= preSaleStartTime && block.timestamp <= preSaleStopTime, "Out of presale time range");
        require(msg.value >= minBuy && msg.value <= maxBuy, "Amount should be between minBuy and maxBuy");
        require(msg.value == calculatePrice(_numOfTokens), "Payment amount is not as per required");
        require(IERC20(tokenContract).balanceOf(address(this)) >= _numOfTokens, "Contract doesn't have enough balance");
        
        IERC20(tokenContract).safeTransfer(msg.sender, _numOfTokens);

        preSaleTokensSold = preSaleTokensSold.add(_numOfTokens);

        emit Buy(msg.sender, _numOfTokens);
    }
    
    /**
     * @dev Function to withdraw MATIC 
     */
    function withdrawAmount(address _to, uint256 _amount) external onlyOwner nonReentrant {
        require(_to != address(0), "_to is Zero Address");
        uint256 balance = address(this).balance;
        require(balance >= _amount, "Insufficient balance");
        
        payable(_to).transfer(balance);
    }
     
    /**
     * @dev Function to withdraw unsold tokens 
     */
    function withdrawTokens(address _to, uint256 _amount) external onlyOwner nonReentrant {
        require(_to != address(0), "_to is Zero Address");
        uint256 balance = IERC20(tokenContract).balanceOf(address(this));
        require(balance >= _amount, "Insufficient balance");
        
        preSaleTokens = preSaleTokens.sub(_amount);
        IERC20(tokenContract).safeTransfer(_to, _amount);
    }
}