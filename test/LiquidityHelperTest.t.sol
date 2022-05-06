// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/ds-test.git/src/cheat.sol";
import "../lib/ds-test.git/src/test.sol";
import "../src/LiquidityHelper.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ILIquidityHelper.sol";

contract LiquidityHelperTest is DSTest, ILiquidityHelper {
    Vm cheat = Vm(HEVM_ADDRESS);
    LiquidityHelper helper;
    //ALCHEMICA
    address[4] alchemica = [
        0x403E967b044d4Be25170310157cB1A4Bf10bdD0f,
        0x44A6e0BE76e1D9620A7F76588e4509fE4fa8E8C8,
        0x6a3E7C3c6EF65Ee26975b12293cA1AAD7e1dAeD2,
        0x42E5E06EF5b90Fe15F853F59299Fc96259209c5C
    ];
    address qRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address GHST = 0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7;
    address mSig = 0xD4151c984e6CF33E04FFAAF06c3374B2926Ecc64;
    address overlord = 0x3a79bF3555F33f2adCac02da1c4a0A0163F666ce;

    //PAIR ADDRESSES
    address[4] pairAddresses = [
        0xfEC232CC6F0F3aEb2f81B2787A9bc9F6fc72EA5C,
        0x641CA8d96b01Db1E14a5fBa16bc1e5e508A45f2B,
        0xC765ECA0Ad3fd27779d36d18E32552Bd7e26Fd7b,
        0xBFad162775EBfB9988db3F24ef28CA6Bc2fB92f0
    ];

    function setUp() public {
        cheat.label(overlord, "OVERLORD");
        helper = new LiquidityHelper(
            alchemica,
            pairAddresses,
            qRouter,
            GHST,
            mSig
        );
        //fund the helper contract with approx 100 alchemica each
        cheat.startPrank(overlord);

        IERC20(alchemica[0]).transfer(address(helper), 100e18);
        IERC20(alchemica[1]).transfer(address(helper), 100e18);
        IERC20(alchemica[2]).transfer(address(helper), 100e18);
        IERC20(alchemica[3]).transfer(address(helper), 100e18);

        cheat.stopPrank();
        //get some ghst too
        //get 500ghst
        cheat.prank(0x971485fc8f9006DfA95DE181D53AE86c03bBF5B1);
        IERC20(GHST).transfer(address(helper), 500e18);
        IERC20(GHST).balanceOf(address(helper));
    }

    function testProvideAndWithdrawLiquidity() public {
        //add 100 fud liquidity
        //at current rates...at least 10LP tokens are obtained
        helper.addLiquidity(
            AddLiquidityArgs(GHST, alchemica[0], 10e18, 100e18, 0, 0, true)
        );
        uint avail = IERC20(pairAddresses[0]).balanceOf(address(helper));
        //remove liquidity

        helper.withdrawLiquidity(
            RemoveLiquidityArgs(GHST, alchemica[0], avail, 0, 0, true)
        );
    }

    function testBatchProvideAndWithdrawLiquidity() public {
        //construct array
        AddLiquidityArgs[] memory args = new AddLiquidityArgs[](4);
        args[0] = AddLiquidityArgs(
            GHST,
            alchemica[0],
            10e18,
            100e18,
            0,
            0,
            true
        );
        args[1] = AddLiquidityArgs(
            GHST,
            alchemica[1],
            10e18,
            100e18,
            0,
            0,
            true
        );
        args[2] = AddLiquidityArgs(
            GHST,
            alchemica[2],
            10e18,
            100e18,
            0,
            0,
            true
        );
        args[3] = AddLiquidityArgs(
            GHST,
            alchemica[3],
            10e18,
            100e18,
            0,
            0,
            true
        );
        helper.batchAddLiquidity(args);

        //get available liquidity
        uint availFud = IERC20(pairAddresses[0]).balanceOf(address(helper));
        uint availFomo = IERC20(pairAddresses[1]).balanceOf(address(helper));
        uint availAlpha = IERC20(pairAddresses[2]).balanceOf(address(helper));
        uint availKek = IERC20(pairAddresses[3]).balanceOf(address(helper));

        //emit liquidity balances to console
        emit log_uint(availFud);
        emit log_uint(availFomo);
        emit log_uint(availAlpha);
        emit log_uint(availKek);

        RemoveLiquidityArgs[] memory args2 = new RemoveLiquidityArgs[](4);
        args2[0] = RemoveLiquidityArgs(
            GHST,
            alchemica[0],
            availFud,
            0,
            0,
            true
        );
        args2[1] = RemoveLiquidityArgs(
            GHST,
            alchemica[1],
            availFomo,
            0,
            0,
            true
        );
        args2[2] = RemoveLiquidityArgs(
            GHST,
            alchemica[2],
            availAlpha,
            0,
            0,
            true
        );
        args2[3] = RemoveLiquidityArgs(
            GHST,
            alchemica[3],
            availKek,
            0,
            0,
            true
        );
        helper.batchRemoveLiquidity(args2);
    }
}