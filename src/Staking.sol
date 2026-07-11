// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.34;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Staking {
    using SafeERC20 for IERC20;
    IERC20 private rewardToken;
    IERC20 private stakedToken;

    uint256 public accumulatedRewardPerShare;
    uint256 public rewardStartBlock;
    uint256 public rewardEndBlock;
    uint256 public rewardPerBlock;
    uint256 private totalShareAmount;
    uint256 public lastRewardBlock;
    uint256 public immutable PRECISION_FACTOR;

    mapping(address => UserInfo) private userInfo;
    struct UserInfo {
        uint256 amount;
        uint256 rewardPerSharePaid;
    }
    struct TokenConfig {
        address stakedToken;
        address rewardToken;
        uint8 rewardTokenDecimals;
    }
    struct RewardConfig {
        uint256 rewardPerBlock;
        uint256 rewardStartBlock;
        uint256 rewardEndBlock;
    }

    constructor(
        address initialOwner, 
        TokenConfig memory tokenConfig, 
        RewardConfig memory rewardConfig)
        Ownable(initialOwner)
    {
        stakedToken = IERC20(tokenConfig.stakedToken);
        rewardToken = IERC20(tokenConfig.rewardToken);

        rewardPerBlock = rewardConfig.rewardPerBlock;
        rewardStartBlock = rewardConfig.rewardStartBlock;

        rewardEndBlock = rewardConfig.rewardEndBlock;

        require(tokenConfig.rewardTokenDecimals < 19, "Decimals of reward token must be less than 19");

        PRECISION_FACTOR = 1e28;

        lastRewardBlock = rewardStartBlock;
    }


    function deposit() external {
        _updatePoolRewards();
        _payPendingRewards();
        _increaseStake();
    }

    function _updatePoolRewards() internal {
      
         if(block.number<=lastRewardBlock){
            return;
         }
         if(totalShareAmount==0){
            return;
         }
         uint256 reward = rewardPerBlock*_getRewardBlockCount(lastRewardBlock,block.number);
         accumulatedRewardPerShare+=reward*PRECISION_FACTOR/totalShareAmount;
    }

    function _payPendingRewards() internal{

    }

    function _increaseStake() internal{
        
    }

}
