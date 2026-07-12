// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.34;

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
