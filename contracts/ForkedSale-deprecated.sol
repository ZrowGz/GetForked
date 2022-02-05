// SPDX-License-Identifier: MIT

// requires compiling with 0.5.5 due to dependencies
pragma solidity ^0.5.0;

// import whitelisted
// import "https://github.com/ConsenSysMesh/openzeppelin-solidity/blob/d5f06ab32ff40bf447fa34bcdb997b54e2499ee0/contracts/crowdsale/validation/WhitelistedCrowdsale.sol";
import "FORKED.sol";
import "https://github.com/ConsenSysMesh/openzeppelin-solidity/blob/d5f06ab32ff40bf447fa34bcdb997b54e2499ee0/contracts/crowdsale/Crowdsale.sol";
import "https://github.com/ConsenSysMesh/openzeppelin-solidity/blob/d5f06ab32ff40bf447fa34bcdb997b54e2499ee0/contracts/crowdsale/emission/MintedCrowdsale.sol";



// Create 
contract ForkedCrowdsale is Crowdsale, MintedCrowdsale { // UPDATE THE CONTRACT SIGNATURE TO ADD INHERITANCE
    
    // Provide parameters for all of the features of your crowdsale, such as the `rate`, `wallet` for fundraising, and `token`.
    constructor(
        uint256 rate,
        address payable wallet,
        Forked token
    )
        MintedCrowdsale()
        Crowdsale(rate, wallet, token)
        public
    {
        // constructor can stay empty
    }
}


contract ForkedCrowdsaleDeployer {
    // Create an `address public` variable called `kasei_token_address`.
    address public forkedTokenAddress;
    // Create an `address public` variable called `kasei_crowdsale_address`.
    address public forkedCrowdsaleAddress;

    // Add the constructor.
    constructor(
        string memory name, 
        string memory symbol, 
        address payable wallet
    ) public {
        // Create a new instance of the KaseiCoin contract
        Forked token = new Forked(name, symbol);
        
        // Assign the token address to `kasei_token_address` variable.
        forkedTokenAddress = address(token);

        // Create a new instance of the `KaseiCoinCrowdsale` contract
        // using a value of 1 will maintain parity with ether (1 eth = 1 kaseicoin)
        ForkedCrowdsale forkedCrowdsale = new ForkedCrowdsale(
            4000,   // rate; # of FORKED per ETH
            wallet, // address to send ETH to 
            token   // the token
        );
            
        // Aassign the `KaseiCoinCrowdsale` contract’s address to the `kasei_crowdsale_address` variable.
        forkedCrowdsaleAddress = address(forkedCrowdsale);

        // Set the `KaseiCoinCrowdsale` contract as a minter
        token.addMinter(forkedCrowdsaleAddress);
        
        // Have the `KaseiCoinCrowdsaleDeployer` renounce its minter role.
        token.renounceMinter();
    }
}
