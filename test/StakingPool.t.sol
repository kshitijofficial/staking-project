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

    function testDepositZeroAmount() public {
        address depositor = makeAddr("depositor");
        vm.startPrank(depositor);
        stake.deposit(0);
        vm.stopPrank();
        assertEq(stake.getTotalShareAmount(), 0, "State Error: totalStakedAmount should be 0");
    }

    function testMultipleDeposits() public {
        address depositor = makeAddr("depositor");
        vm.startPrank(depositor);
        stakedToken.mint(depositor, 1000);
        stakedToken.approve(address(stake), 1000);
        
        stake.deposit(10);
        assertEq(stake.getTotalShareAmount(), 10);
        
        stake.deposit(20);
        assertEq(stake.getTotalShareAmount(), 30);
        vm.stopPrank();
    }

    function testWithdrawPartially() public {
        address depositor = makeAddr("depositor");
        vm.startPrank(depositor);
        stakedToken.mint(depositor, 1000);
        stakedToken.approve(address(stake), 1000);
        
        stake.deposit(50);
        stake.withdraw(20);
        vm.stopPrank();
        
        assertEq(stake.getTotalShareAmount(), 30);
        assertEq(stakedToken.balanceOf(depositor), 970);
    }

    function testWithdrawFully() public {
        address depositor = makeAddr("depositor");
        vm.startPrank(depositor);
        stakedToken.mint(depositor, 1000);
        stakedToken.approve(address(stake), 1000);
        
        stake.deposit(50);
        stake.withdraw(50);
        vm.stopPrank();
        
        assertEq(stake.getTotalShareAmount(), 0);
        assertEq(stakedToken.balanceOf(depositor), 1000);
    }

    function testWithdrawMoreThanStaked() public {
        address depositor = makeAddr("depositor");
        vm.startPrank(depositor);
        stakedToken.mint(depositor, 1000);
        stakedToken.approve(address(stake), 1000);
        
        stake.deposit(50);
        stake.withdraw(100);
        vm.stopPrank();
        
        assertEq(stake.getTotalShareAmount(), 50); // State unchanged due to early return
    }

    function testPendingRewardsAccumulation() public {
        address depositor = makeAddr("depositor");
        rewardToken.mint(address(stake), 100000000000000000000); // Give staking contract some tokens to pay rewards

        vm.startPrank(depositor);
        stakedToken.mint(depositor, 1000);
        stakedToken.approve(address(stake), 1000);
        
        vm.roll(1); // Block 1 (start block)
        stake.deposit(50);
        
        vm.roll(2); // Block 2 (1 block passed, 1 rewardToken per block)
        stake.withdraw(0); // Trigger reward payout without withdrawing stake
        vm.stopPrank();
        
        // At block 2, 1 block passed since deposit at block 1. Reward should be 1e18.
        assertEq(rewardToken.balanceOf(depositor), 1e18);
    }

    function testClaimRewardsOnDeposit() public {
        address depositor = makeAddr("depositor");
        rewardToken.mint(address(stake), 100000000000000000000);

        vm.startPrank(depositor);
        stakedToken.mint(depositor, 1000);
        stakedToken.approve(address(stake), 1000);
        
        vm.roll(1);
        stake.deposit(50);
        
        vm.roll(3); // 2 blocks passed, reward = 2e18
        stake.deposit(10); // Another deposit should trigger payout
        vm.stopPrank();
        
        assertEq(rewardToken.balanceOf(depositor), 2e18);
        assertEq(stake.getTotalShareAmount(), 60);
    }

    function testClaimRewardsOnWithdraw() public {
        address depositor = makeAddr("depositor");
        rewardToken.mint(address(stake), 100000000000000000000);

        vm.startPrank(depositor);
        stakedToken.mint(depositor, 1000);
        stakedToken.approve(address(stake), 1000);
        
        vm.roll(1);
        stake.deposit(50);
        
        vm.roll(4); // 3 blocks passed, reward = 3e18
        stake.withdraw(50);
        vm.stopPrank();
        
        assertEq(rewardToken.balanceOf(depositor), 3e18);
        assertEq(stake.getTotalShareAmount(), 0);
    }

    function testRewardsStopAfterEndBlock() public {
        address depositor = makeAddr("depositor");
        rewardToken.mint(address(stake), 100000000000000000000);

        vm.startPrank(depositor);
        stakedToken.mint(depositor, 1000);
        stakedToken.approve(address(stake), 1000);
        
        vm.roll(1);
        stake.deposit(50);
        
        vm.roll(10); // Passed end block (8). Max blocks = 7 (from 1 to 8). Reward = 7e18.
        stake.withdraw(50);
        vm.stopPrank();
        
        assertEq(rewardToken.balanceOf(depositor), 7e18);
    }

    function testStopRewards() public {
        address owner = makeAddr("owner");
        vm.roll(5);
        vm.prank(owner);
        stake.stopRewards();
        
        assertEq(stake.rewardEndBlock(), 5);
    }

    function testUpdateRewardPerBlock() public {
        address owner = makeAddr("owner");
        vm.prank(owner);
        stake.updateRewardPerBlock(2e18);
        
        assertEq(stake.rewardPerBlock(), 2e18);
    }

    function testWithdrawWrongStakedTokens() public {
        address owner = makeAddr("owner");
        address wrongToken = address(new ERC20Mock());
        
        ERC20Mock(wrongToken).mint(address(stake), 100);
        
        vm.prank(owner);
        stake.withdrawWrongStakedTokens(wrongToken, owner, 100);
        
        assertEq(ERC20Mock(wrongToken).balanceOf(owner), 100);
        assertEq(ERC20Mock(wrongToken).balanceOf(address(stake)), 0);
    }

    function testCannotWithdrawStakedOrRewardTokens() public {
        address owner = makeAddr("owner");
        
        vm.startPrank(owner);
        vm.expectRevert("Cannot withdraw Staked Tokens");
        stake.withdrawWrongStakedTokens(address(stakedToken), owner, 100);
        
        vm.expectRevert("Cannot withdraw Rewared Tokens");
        stake.withdrawWrongStakedTokens(address(rewardToken), owner, 100);
        vm.stopPrank();
    }

    function testNonOwnerCannotCallAdminFunctions() public {
        address nonOwner = makeAddr("nonOwner");
        vm.startPrank(nonOwner);
        
        vm.expectRevert();
        stake.stopRewards();
        
        vm.stopPrank();
    }
}
