import { useContract } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

export const useContracts = () => {
  const { contract: adventurerContract } = useContract({
    address:
      "0x035d755a23ec72df90819f584d9a1849bbc21fa77f96d25e03f1736883895248",
    abi: Adventurer,
  });

  const { contract: lootMarketArcadeContract } = useContract({
    address:
      "0x065669e15c8f1a7f17b7062e4eb1b709b922b931b93c59577f1848a85c30ab1f",
    abi: LootMarketArcade,
  });

  const { contract: beastContract } = useContract({
    address:
      "0x000f4dbfe5d15792aa91025e42ee1d74c22bdeb1eef0b9bc19a37216377290c1",
    abi: Beast,
  });

  const { contract: lordsContract } = useContract({
    address:
      "0x023b86be0b3da5c2fdbd80d1d57f1b54391588ba338acecdd014a208d47ba9ca",
    abi: Lords_ERC20_Mintable,
  });

  return {
    adventurerContract,
    lootMarketArcadeContract,
    beastContract,
    lordsContract,
  };
};
