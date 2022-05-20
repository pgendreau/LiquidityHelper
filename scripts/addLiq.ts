import { ethers, run } from "hardhat";
import { convertAddLiquidityArgsToString } from "../tasks/addLiquidity";
import { AddLiquidityArgsStruct } from "../typechain-types/LiquidityHelper";
import {
  AddLiquidityTaskArgs,
  alchemicas,
  GHST,
  multisigAddress,
} from "./libs/liqParamHelpers";

const args: AddLiquidityArgsStruct[] = [
  {
    _tokenA: alchemicas[0],
    _tokenB: GHST,
    _amountADesired: ethers.utils.parseEther("833230"),
    _amountBDesired: ethers.utils.parseEther("11820.04464"),
    _amountAMin: 0,
    _amountBMin: 0,
  },
  {
    _tokenA: alchemicas[1],
    _tokenB: GHST,
    _amountADesired: ethers.utils.parseEther("439135"),
    _amountBDesired: ethers.utils.parseEther("11801.77731"),
    _amountAMin: 0,
    _amountBMin: 0,
  },
  {
    _tokenA: alchemicas[2],
    _tokenB: GHST,
    _amountADesired: ethers.utils.parseEther("660333"),
    _amountBDesired: ethers.utils.parseEther("123868.7625"),
    _amountAMin: 0,
    _amountBMin: 0,
  },
  {
    _tokenA: alchemicas[3],
    _tokenB: GHST,
    _amountADesired: ethers.utils.parseEther("242103"),
    _amountBDesired: ethers.utils.parseEther("69604.7275"),
    _amountAMin: 0,
    _amountBMin: 0,
  },
];
export async function addLiquidity() {
  const payload: AddLiquidityTaskArgs = {
    multisig: multisigAddress,
    functionArguments: convertAddLiquidityArgsToString(args),
    useMultisig: true,
  };

  await run("addLiquidity", payload);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  addLiquidity()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}
