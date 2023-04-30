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
        baseUrl: "http://survivor-indexer.bibliothecadao.xyz:5050",
        rpcUrls: ["http://survivor-indexer.bibliothecadao.xyz:5050/rpc"],
        // accountImplementation:
        //   "0x3ebe39375ba9e0f8cc21d5ee38c48818e8ed6612fa2e4e04702a323d64b96ba",
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
          name: "Ether",
        },
      },
    });
  };

  return (
    <Button onClick={() => handeleAddDevnetEth()}>Add Devnet ETH Token</Button>
  );
};

export const MintEthButton = () => {
  const { account } = useAccount();

  const handeleMintEth = async () => {
    if (account?.address) {
      await mintEth({ address: account?.address });
    }
  };

  return <Button onClick={() => handeleMintEth()}>Mint ETH</Button>;
};
