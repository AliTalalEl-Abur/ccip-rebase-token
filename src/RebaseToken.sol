// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
* @title RebaseToken
* @author @Ali Talal
* @notice This is a cross chain rebase token that incentivises users to deposit into a vault and gai
* @notice the interest rate in the Smart contract can only decrease
* @notice each user will have their interest rate that is the global interest rate at the time of deposit
*/
contract RebaseToken is ERC20 {
    error RebaseToken_InterestRateOnlyCanDecrease(uint256 _oldInterestRate, uint256 _newInterestRate);
    
    uint256 private constant PRECISION_FACTOR = 1e18;
    uint256 private s_interestRate = 5e10;
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    event InterestRateSet(uint256 _newInterestRate);
    constructor() ERC20("Rebase Token", "RBT") {

    }


    function calculateUserAccumulatedInterestSinceLastUpdate(address _user) internal view returns (uint256 linearInterest) {
        //we need to calculate the interest that has accumulated since the last update
        // this is going to be linear growth with time
        // 1. calculate the time since the last update
        // 2. calculate the amount of linear growth
        // (principal amount) + (principal amount * user interest rate * time elapsed)
        // deposit: 10 tokens
        // interest rate 0.5 tokens per second
        // time elapsed is 2 seconds
        // 10 + (10 * 0.5 * 2)
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        linearInterest = PRECISION_FACTOR + (s_userInterestRate[_user] * timeElapsed);

    }
    /*
    * @notice Set the interest rate in the contract
    * @param _newInterestRate The new interest rate to set
    * @dev The interest rate can only decrease
    */

    function setInterestRate(uint256 _newInterestRate) external {
        //Set interest rate
        if (_newInterestRate < s_interestRate){
            revert RebaseToken_InterestRateOnlyCanDecrease(s_interestRate, _newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);

    }
    // deberia ser:
    /*if (_newInterestRate >= s_interestRate) {
    revert RebaseToken_InterestRateOnlyCanDecrease(
        s_interestRate,
        _newInterestRate
    );
    }
    */

    /*
    * @notice Mint the user tokens when they deposit into the vault
    * @param _to The user to mint the tokens to
    * @param _amount The amount of tokens to mint
    */
    function mint(address _to, uint256 amount) external {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, amount);
    }

    /*
    * calculate the balance for the user including the interest that has accumulated since the last update
    * (principle balance) + some interest that has accrued
    * @param _user The user to calculate the balance for
    * @return The balance of the user including the interest that has accumulated since the last update
    */

    function balanceOf(address _user) public view override returns (uint256) {
        // get the current principle balance of the user (the number of tokens that have actually been minted to the user
        // multiply the principle balance by interest rate that has accumulated time since the balance
        return super.balanceOf(_user) * calculateUserAccumulatedInterestSinceLastUpdate(_user)/PRECISION_FACTOR;
    }

    /*
    * @notice Calculate the interest that has accumulated since the last update
    * @param _user The user to calculate the interest accumulated for
    * @return The interest that has accumulated since the last update
    */

    function _mintAccruedInterest(address _to) internal {
        // find their current balance of rebase tokens that have been minted to the user -> principal balance
        // calculate their current balance including any interest.-> balanceOf
        // calculate the number of tokens that need to be minted to the user -> (2) - (1)
        // call _mint to mint the tokens to the user
        // set the users last updated timestamp to now
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
        // s_userLastUpdatedTimestamp[_to] = block.timestamp;
    }

    /*
    * @notice Get the interest rate for the user
    * @param _user The user to get the interest rate for
    * @return The interest rate for the user
    */

    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}

