import { useAccount } from "@starknet-react/core";
import { Button } from "./Button";
import { mintEth } from "../api/api";

export const AddDevnetButton = () => {
  const { connector } = useAccount();
  const wallet = (connector as any)?._wallet;

  const handleAddDevnet = async () => {
    await wallet?.request({
      type: "wallet_addStarknetChain",
      params: {
        id: "90013",
        chainName: "Loot Survivor Devnet",
        chainId: "LS_DEVNET",
        baseUrl: "http://3.215.42.99:5050",
        rpcUrls: ["http://3.215.42.99:5050/rpc"],
      },
    });
  };

  return <Button onClick={() => handleAddDevnet()}>Add Devnet</Button>;
};

export const SwitchToDevnetButton = () => {
  const { connector } = useAccount();
  const wallet = (connector as any)?._wallet;

  const handeleSwitchToDevnet = async () => {
    console.log(
      await wallet?.request({
        type: "wallet_switchStarknetChain",
        params: {
          id: "90013",
          name: "Loot Survivor Devnet",
          chainId: "LS_DEVNET",
          baseUrl: "http://3.215.42.99:5050",
          rpcUrls: ["http://3.215.42.99:5050/rpc"],
        },
      })
    );
  };

  return (
    <Button onClick={() => handeleSwitchToDevnet()}>Switch To Devnet</Button>
  );
};

export const AddDevnetEthButton = () => {
  const { connector } = useAccount();
  const wallet = (connector as any)?._wallet;

  const handeleAddDevnetEth = async () => {
    await wallet?.request({
      type: "wallet_watchAsset",
      params: {
        type: "ERC20",
        options: {
          address:
            "0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7",
          symbol: "ETH",
          decimals: 18,
          name: "ETher",
        },
      },
    });
  };

  return (
    <Button onClick={() => handeleAddDevnetEth()}>Add Devnet ETH Token</Button>
  );
};

// export const MintEthButton = () => {
//   const { account } = useAccount();

//   const handeleMintEth = () => {
//     if (account?.address) {
//       mintEth(account?.address);
//     }
//   };

//   return <Button onClick={() => handeleMintEth()}>Mint ETH</Button>;
// };
