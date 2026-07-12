// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.34;

import {Test} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract StakingPool is Test {
  Staking stake;
  function setUp() public {
        address owner = makeAddr("owner");
        tokenConfig = TokenConfig({
            stakedToken: address(0x1),
            rewardToken: address(0x2),
            rewardTokenDecimals: 18
        });
        rewardConfig = RewardConfig({
            rewardPerBlock: 1e18,
            rewardStartBlock: block.number,
            rewardEndBlock: block.number + 100
        });
        stake = new Staking(address(owner), tokenConfig, rewardConfig);
    }

    function testWhenUserDepositsForTheFirstTime() public {
        uint256 amount = 10;
        stake.deposit(amount);
        //totalStakedAmount
        //depositor staked transfer contract - balance of depostor and the staking contract
    }
}