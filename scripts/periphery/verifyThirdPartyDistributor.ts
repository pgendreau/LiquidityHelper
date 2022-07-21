/* global task ethers */
import { run } from 'hardhat'
import { DistributionStruct } from "../../typechain-types/ThirdPartyDistributor";
async function verifyThirdPartyDistributor(
  deployedAddress: string,
  owner: string,
  distribution: DistributionStruct[],
  releaseAccess: number,
) {
  await run('verify:verify', {
    address: deployedAddress,
    constructorArguments: [
      owner,
      [
        {
          beneficiary: "0x73DA56CB889AFb72ADB2879d08233f8bACA2c362",
          proportion: 50
        },
        {
          beneficiary: "0xdC6b22E172E4125c7a080090E3A231AcFe381af3",
          proportion: 50
        }
      ],
      releaseAccess,
    ],
  })
}

verifyThirdPartyDistributor(
  '0x6733451a24472d015F6686Fd988d04babCE78ab3',
  '0x43FF4C088df0A425d1a519D3030A1a3DFff05CfD',
   [
     {
       beneficiary: "0x73DA56CB889AFb72ADB2879d08233f8bACA2c362",
       proportion: 50
     },
     {
       beneficiary: "0xdC6b22E172E4125c7a080090E3A231AcFe381af3",
       proportion: 50
     }
   ],
   0
)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
