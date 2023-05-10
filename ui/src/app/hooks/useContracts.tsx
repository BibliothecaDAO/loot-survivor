import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

const testnet_addr = "https://survivor-indexer.bibliothecadao.xyz";

export const contracts = {
  testnet: {
    adventurer:
      "0x0457395419b1aee6373d7058a8aca83dbf6ce6658c8a1fa2d996a8ddbcfe1378",
    lootMarketArcade:
      "0x01eaacc401583b025895766acf51422956e761d10dad4bcdee76ccc6946be90f",
    beast: "0x064b38fedecf2afa53c6ee774cf9cad57b5b50ae568101cd8dfaeed510539e19",
    lords_erc20_mintable:
      "0x04d460ca5ae8059766c5df1c65633f492019e109a859b3437d3c3990ee31fe17",
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
