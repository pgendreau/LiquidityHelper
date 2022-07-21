import { ethers } from "hardhat";

import { DistributionStruct } from "../../typechain-types/ThirdPartyDistributor";


export async function deployThirdPartyDistributor() {
  const owner = "0x43FF4C088df0A425d1a519D3030A1a3DFff05CfD";
  const distributions: DistributionStruct[] = [
    {
      beneficiary: "0x73DA56CB889AFb72ADB2879d08233f8bACA2c362",
      proportion: 50
    },
    {
      beneficiary: "0xdC6b22E172E4125c7a080090E3A231AcFe381af3",
      proportion: 50
    }
  ];
  const releaseAccess = 0;

  const ThirdPartyDistributor = await ethers.getContractFactory("ThirdPartyDistributor");
  const helper = await ThirdPartyDistributor.deploy(
    owner,
    distributions,
    releaseAccess
  );

  //@ts-ignore
  //   const helper = (await ThirdPartyDistributor.deploy(
  //     owner,
  //     _distributions,
  //     _releaseAccess,
  //   )) as ThirdPartyDistributor
  await helper.deployed();

  console.log("ThirdPartyDistributor deployed to", helper.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployThirdPartyDistributor()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}
