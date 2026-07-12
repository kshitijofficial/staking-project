// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.34;

import {Test} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {TokenConfig, RewardConfig} from "../src/Types.sol";

contract StakingPool is Test {
    Staking stake;
    ERC20Mock stakedToken;
    ERC20Mock rewardToken;

    function setUp() public {
        address owner = makeAddr("owner");
        stakedToken = new ERC20Mock();
        rewardToken = new ERC20Mock();

        TokenConfig memory tokenConfig = TokenConfig({stakedToken: address(stakedToken), rewardToken: address(rewardToken), rewardTokenDecimals: 18});
        RewardConfig memory rewardConfig =
            RewardConfig({rewardPerBlock: 1e18, rewardStartBlock: 1, rewardEndBlock: 8});
        stake = new Staking(address(owner), tokenConfig, rewardConfig);
    }

    function testWhenUserDepositsForTheFirstTime() public {
        uint256 amount = 10;
        address depositor = makeAddr("depositor");

        uint256 depositorBalanceBefore = stakedToken.balanceOf(depositor);

        uint256 stakeContractBalanceBefore = stakedToken.balanceOf(address(stake));
        
        vm.startPrank(depositor);
        stakedToken.mint(depositor, 1000);
        stakedToken.approve(address(stake),20);
        stake.deposit(amount);
        vm.stopPrank();
        uint256 depositorBalanceAfter = stakedToken.balanceOf(depositor);
        uint256 stakeContractBalanceAfter = stakedToken.balanceOf(address(stake));

        assertEq(stake.getTotalShareAmount(), amount, "State Error: totalStakedAmount did not update correctly");
        assertEq(
            depositorBalanceAfter,
            depositorBalanceBefore - amount,
            "Token Error: Depositor balance did not decrease by the deposit amount"
        );
        assertEq(
            stakeContractBalanceAfter,
            stakeContractBalanceBefore + amount,
            "Token Error: Staking contract balance did not increase by the deposit amount"
        );
    }
}
