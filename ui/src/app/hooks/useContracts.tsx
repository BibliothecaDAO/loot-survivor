import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

export const useContracts = () => {
  const { account } = useAccount();

  const { contract: adventurerContract } = useContract({
    address:
      (account as any)?.baseUrl == "http://3.215.42.99:5050"
        ? "0x005160ffc8910638190fbe80296932ce90be9091f622b30b299ed81c7be7d359"
        : "0x035d755a23ec72df90819f584d9a1849bbc21fa77f96d25e03f1736883895248",
    abi: Adventurer,
  });

  const { contract: lootMarketArcadeContract } = useContract({
    address:
      (account as any)?.baseUrl == "http://3.215.42.99:5050"
        ? "0x040583a9197a52f289a5f6f03981ace0b3dfcc7496137fa292ec67796be22766"
        : "0x065669e15c8f1a7f17b7062e4eb1b709b922b931b93c59577f1848a85c30ab1f",
    abi: LootMarketArcade,
  });

  const { contract: beastContract } = useContract({
    address:
      (account as any)?.baseUrl == "http://3.215.42.99:5050"
        ? "0x061533cb6f21d230aeef9ac2aecf0c70679d1d50d9d61f11bd6a6113cf3d7d85"
        : "0x000f4dbfe5d15792aa91025e42ee1d74c22bdeb1eef0b9bc19a37216377290c1",
    abi: Beast,
  });

  const { contract: lordsContract } = useContract({
    address:
      (account as any)?.baseUrl == "http://3.215.42.99:5050"
        ? "0x0684f30e64d9d576db851a6d629b73a0282c8ddfa35b6fd59a4f614df4b025c5"
        : "0x023b86be0b3da5c2fdbd80d1d57f1b54391588ba338acecdd014a208d47ba9ca",
    abi: Lords_ERC20_Mintable,
  });

  return {
    adventurerContract,
    lootMarketArcadeContract,
    beastContract,
    lordsContract,
  };
};
