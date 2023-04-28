import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

export const useContracts = () => {
  const { account } = useAccount();

  const { contract: adventurerContract } = useContract({
    address:
      (account as any)?.baseUrl ==
      "http://survivor-indexer.bibliothecadao.xyz:5050"
        ? "0x009056f46cb33d53c479b1d7c063c196bcd4e3549d58c9c9555b8bd2fea5ff4d"
        : "0x035d755a23ec72df90819f584d9a1849bbc21fa77f96d25e03f1736883895248",
    abi: Adventurer,
  });

  const { contract: lootMarketArcadeContract } = useContract({
    address:
      (account as any)?.baseUrl ==
      "http://survivor-indexer.bibliothecadao.xyz:5050"
        ? "0x0216071afae3defb274a33c6de4b5480fe3a4dd40c4832f69363b65f1ccd4614"
        : "0x065669e15c8f1a7f17b7062e4eb1b709b922b931b93c59577f1848a85c30ab1f",
    abi: LootMarketArcade,
  });

  const { contract: beastContract } = useContract({
    address:
      (account as any)?.baseUrl ==
      "http://survivor-indexer.bibliothecadao.xyz:5050"
        ? "0x028298b791b7d938a063be38799ca1e217afc9a18e2af085031920f50cd4e006"
        : "0x000f4dbfe5d15792aa91025e42ee1d74c22bdeb1eef0b9bc19a37216377290c1",
    abi: Beast,
  });

  const { contract: lordsContract } = useContract({
    address:
      (account as any)?.baseUrl ==
      "http://survivor-indexer.bibliothecadao.xyz:5050"
        ? "0x025cc653405372411731fc0d187d14897db48be93609120beb18fdbbf547375b"
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
