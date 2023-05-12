import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

const testnet_addr = "https://survivor-indexer.bibliothecadao.xyz";

export const contracts = {
  testnet: {
    adventurer:
      "0x03fb428dcb56d42b9ae3e2687698b63c66b41f55d7528a4b7819dfe02c06653c",
    lootMarketArcade:
      "0x0333529dc1293ae28ab3c7b89b4edfd8f49a7eed94485beecda1cee070bf5fb7",
    beast: "0x057a1498976866ff1850957925ff70a9ee903f0cbe5b085e168de0304426c76d",
    lords_erc20_mintable:
      "0x03492ba6e57e8cb3c7776c505a1b2c1b8bc857076c28c888f3cc187918c95c60",
  },
  goerli: {
    adventurer:
      "0x02d5088c014923bdf3b1bac23c7333275743b3733dc1f0693b84706a715b1bc6",
    lootMarketArcade:
      "0x066a894dca52a03aa165050522d058ade9a1e100577aa90c22b11ad22627f0ad",
    beast: "0x07db61dd565afb57c44d6d5fc55853aebfa28205a042b7e8be4872dceba87068",
    lords_erc20_mintable:
      "0x069a0a12241af46476f396784b123f3c7983364c568565c067b81f246ce6f34c",
  },
};

export const useContracts = () => {
  const { account } = useAccount();

  const { contract: adventurerContract } = useContract({
    address:
      (account as any)?.baseUrl == testnet_addr
        ? contracts.testnet.adventurer
        : contracts.goerli.adventurer,
    abi: Adventurer,
  });

  const { contract: lootMarketArcadeContract } = useContract({
    address:
      (account as any)?.baseUrl == testnet_addr
        ? contracts.testnet.lootMarketArcade
        : contracts.goerli.lootMarketArcade,
    abi: LootMarketArcade,
  });

  const { contract: beastContract } = useContract({
    address:
      (account as any)?.baseUrl == testnet_addr
        ? contracts.testnet.beast
        : contracts.goerli.beast,
    abi: Beast,
  });

  const { contract: lordsContract } = useContract({
    address:
      (account as any)?.baseUrl == testnet_addr
        ? contracts.testnet.lords_erc20_mintable
        : contracts.goerli.lords_erc20_mintable,
    abi: Lords_ERC20_Mintable,
  });

  return {
    adventurerContract,
    lootMarketArcadeContract,
    beastContract,
    lordsContract,
  };
};
