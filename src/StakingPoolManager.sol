// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.34;

import {Staking} from "./Staking.sol";
import {TokenConfig, RewardConfig} from "./Types.sol";

contract StakingPoolManager {
    address[] private stakings;

    function createStakingPool(TokenConfig memory tokenConfig, RewardConfig memory rewardConfig) external {
        Staking staking = new Staking(msg.sender, tokenConfig, rewardConfig);
        stakings.push(address(staking));
    }
}
