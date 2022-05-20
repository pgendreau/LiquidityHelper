import { ethers, run } from "hardhat";
import { convertAddLiquidityArgsToString } from "../tasks/addLiquidity";
import { convertArrayToString } from "../tasks/transferOutTokens";
import { AddLiquidityArgsStruct } from "../typechain-types/LiquidityHelper";
import {
  AddLiquidityTaskArgs,
  alchemicas,
  GHST,
  multisigAddress,
  transferTokenInTaskArgs,
  transferTokenOutTaskArgs,
} from "./libs/liqParamHelpers";

export async function transferInTokens() {
  const amounts = [
    ethers.utils.parseEther("833130").toString(),
    ethers.utils.parseEther("439135").toString(),
    ethers.utils.parseEther("660333").toString(),
    ethers.utils.parseEther("242103").toString(),
  ];

  for (let index = 3; index < alchemicas.length; index++) {
    const payload: transferTokenInTaskArgs = {
      multisig: multisigAddress,
      tokenAddress: GHST,
      amount: ethers.utils.parseEther("200000").toString(),
    };
    await run("transferInTokens", payload);
    index++;
  }

  // const amounts = new Array(4).fill(ethers.utils.parseEther("100").toString());

  // const payload2: transferTokenOutTaskArgs = {
  //   multisig: multisigAddress,
  //   tokenAddresses: convertArrayToString(alchemicas),
  //   amounts: convertArrayToString(amounts),
  //   useMultisig: false,
  // };

  // await run("transferOutTokens", payload2);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  transferInTokens()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}
