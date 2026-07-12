// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.34;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {TokenConfig,RewardConfig} from "./Types.sol";

contract Staking is Ownable,ReentrancyGuard {
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

    constructor(address initialOwner, TokenConfig memory tokenConfig, RewardConfig memory rewardConfig)
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

    function deposit(uint256 amount) external {
        UserInfo storage user = userInfo[msg.sender];
        _updatePoolRewards();
        _payPendingRewards(user, msg.sender);
        _increaseStake(user, msg.sender, amount);

        user.rewardPerSharePaid = (user.amount * accumulatedRewardPerShare) / PRECISION_FACTOR;
    }

    function _updatePoolRewards() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (totalShareAmount == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 reward = rewardPerBlock * _getRewardBlockCount(lastRewardBlock, block.number);
        accumulatedRewardPerShare += reward * PRECISION_FACTOR / totalShareAmount;
        lastRewardBlock = block.number;
    }

    function _getRewardBlockCount(uint256 from, uint256 to) internal view returns (uint256) {
        if (to <= rewardEndBlock) {
            return to - from;
        } else if (from >= rewardEndBlock) {
            return 0;
        } else {
            return rewardEndBlock - from;
        }
    }

    function _payPendingRewards(UserInfo storage user, address account) internal {
        if (user.amount == 0) {
            return;
        }
        uint256 pendingReward = (user.amount * accumulatedRewardPerShare) / PRECISION_FACTOR - user.rewardPerSharePaid;

        if (pendingReward > 0) {
            rewardToken.safeTransfer(account, pendingReward);
        }
    }

    function _increaseStake(UserInfo storage user, address account, uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        user.amount += amount;
        totalShareAmount += amount;
        stakedToken.safeTransferFrom(account, address(this), amount);
    }

    function withdraw(uint256 amount) external {
        UserInfo storage user = userInfo[msg.sender];
        _updatePoolRewards();
       _payPendingRewards(user, msg.sender);
        _decreaseStake(user, msg.sender, amount);
    }

    function _decreaseStake(UserInfo storage user, address account, uint256 amount) internal {
        if (amount > user.amount) {
            return;
        }
        user.amount -= amount;
        totalShareAmount -= amount;
        stakedToken.safeTransfer(account, amount);
    }

    function stopRewards() external onlyOwner {
        rewardEndBlock = block.number;
    }

    function updateRewardPerBlock(uint256 newRewardPerBlock) external onlyOwner {
        require(rewardStartBlock < newRewardPerBlock, "Staking has not started");
        rewardPerBlock = newRewardPerBlock;
    }

    function updateRewardStartBlock(uint256 newRewardStartBlock) external onlyOwner {
        rewardStartBlock = newRewardStartBlock;
    }

    function updateRewardEndBlock(uint256 newRewardEndBlock) external onlyOwner {
        rewardEndBlock = newRewardEndBlock;
    }

  function withdrawWrongStakedTokens(
        address _wrongTokenAddress, 
        address _to, 
        uint256 amount
    ) external onlyOwner {
        
        require(_wrongTokenAddress!=address(stakedToken),"Cannot withdraw Staked Tokens");
        require(_wrongTokenAddress!=address(rewardToken),"Cannot withdraw Rewared Tokens");
        IERC20(_wrongTokenAddress).safeTransfer(_to, _amount);
    }
}
