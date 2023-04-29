import { useContract, useAccount } from "@starknet-react/core";
import Adventurer from "../abi/Adventurer.json";
import LootMarketArcade from "../abi/LootMarketArcade.json";
import Beast from "../abi/Beast.json";
import Lords_ERC20_Mintable from "../abi/Lords_ERC20_Mintable.json";

const testnet_addr = "http://survivor-indexer.bibliothecadao.xyz:5050";

export const contracts = {
  testnet: {
    adventurer:
      "0x0218aef38510a4d1cf523ca0cee301778139d90119a78a3a6e4874986a3ebf2b",
    lootMarketArcade:
      "0x07bdc1dca0de22eb0ffce91dd4995173a0285a1ae9f526a689298dfc3324decb",
    beast: "0x0487ae03df0c66407b1ccdb6d0b5c55b8fef7365f43c30dc554ceeb1b6d4b30c",
    lords_erc20_mintable:
      "0x076952f27f5c6afe3444aea88afa7b2da4caa4c738c1bf800e697c992442e97f",
  },
  goerli: {
    adventurer:
      "0x035d755a23ec72df90819f584d9a1849bbc21fa77f96d25e03f1736883895248",
    lootMarketArcade:
      "0x065669e15c8f1a7f17b7062e4eb1b709b922b931b93c59577f1848a85c30ab1f",
    beast: "0x000f4dbfe5d15792aa91025e42ee1d74c22bdeb1eef0b9bc19a37216377290c1",
    lords_erc20_mintable:
      "0x023b86be0b3da5c2fdbd80d1d57f1b54391588ba338acecdd014a208d47ba9ca",
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
