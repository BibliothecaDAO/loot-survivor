import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

const testnet_addr = "https://survivor-indexer.bibliothecadao.xyz";

export const contracts = {
  testnet: {
    adventurer:
      "0x06edcf9c92fb99b14bcf0a7f016b3f298548425df085483c1d1a68aecae4b4a9",
    lootMarketArcade:
      "0x058899f75e139dd3db67fa6e875c79a12a48328215d93dd688721750389300f8",
    beast: "0x029887bb51387e152aa861f8378e004fad6f99db836293855184540c08072731",
    lords_erc20_mintable:
      "0x017441a8855b221aacb4b4ece57b0665b91ac41fd7d03e481fcd40767c17708d",
  },
  goerli: {
    adventurer:
      "0x02d5088c014923bdf3b1bac23c7333275743b3733dc1f0693b84706a715b1bc6",
    lootMarketArcade:
      "0x066a894dca52a03aa165050522d058ade9a1e100577aa90c22b11ad22627f0ad",
    beast: "0x07db61dd565afb57c44d6d5fc55853aebfa28205a042b7e8be4872dceba87068",
    lords_erc20_mintable:
      "0x04981487ef559795bffcaa8de30aa8f031a49715ba8fd05f18708153e6a387ed",
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
