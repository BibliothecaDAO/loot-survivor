import { useState } from "react";
import { useAccount } from "@starknet-react/core";
import { Button } from "./Button";
import { mintEth } from "../api/api";

interface AddDevnetButtonProps {
  isDisabled: boolean;
  setAddDevnet: (value: boolean) => void;
}

export const AddDevnetButton = ({
  isDisabled,
  setAddDevnet,
}: AddDevnetButtonProps) => {
  const { connector } = useAccount();
  const wallet = (connector as any)?._wallet;

  const handleAddDevnet = async () => {
    await wallet?.request({
      type: "wallet_addStarknetChain",
      params: {
        id: "90013",
        chainName: "Loot Survivor Devnet",
        chainId: "LS_DEVNET",
        baseUrl: "https://3.215.42.99:5050",
        rpcUrls: ["https://3.215.42.99:5050/rpc"],
        // accountImplementation:
        //   "0x58d97f7d76e78f44905cc30cb65b91ea49a4b908a76703c54197bca90f81773",
      },
    });
  };

  return (
    <Button
      onClick={async () => {
        await handleAddDevnet();
        setAddDevnet(true);
      }}
      disabled={isDisabled}
    >
      Add Devnet
    </Button>
  );
};

interface SwitchDevnetButtonProps {
  isDisabled: boolean;
}

export const SwitchToDevnetButton = ({
  isDisabled,
}: SwitchDevnetButtonProps) => {
  const { connector } = useAccount();
  const wallet = (connector as any)?._wallet;

  const handeleSwitchToDevnet = async () => {
    await wallet?.request({
      type: "wallet_switchStarknetChain",
      params: {
        chainId: "LS_DEVNET",
      },
    });
  };

  return (
    <Button
      onClick={async () => {
        await handeleSwitchToDevnet();
      }}
      disabled={isDisabled}
    >
      Switch To Devnet
    </Button>
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
