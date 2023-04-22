import { useAccount } from "@starknet-react/core";

export const AddDevnet = () => {
  const { connector } = useAccount();
  const wallet = (connector as any)?._wallet;

  const handeleAddDevnet = async () => {
    console.log(
      await wallet?.request({
        type: "wallet_addStarknetChain",
        params: {
          id: "90013",
          name: "Loot Survivor Devnet",
          chainId: "LS_DEVNET",
          baseUrl: "http://3.215.42.99:5050",
          rpcUrls: ["http://3.215.42.99:5050/rpc"],
        },
      })
    );
    // await wallet?.request({
    //   type: "wallet_addStarknetChain",
    //   params: {
    //     id: "LS_DEVNET",
    //     name: "Loot Survivor Devnet",
    //     chainId: "90013",
    //     baseUrl: "http://3.215.42.99:5050",
    //     rpcUrls: ["http://3.215.42.99:5050/rpc"],
    //   },
    // })
  };

  return handeleAddDevnet;
};

export const SwitchToDevnet = () => {
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
    // await wallet?.request({
    //   type: "wallet_addStarknetChain",
    //   params: {
    //     id: "LS_DEVNET",
    //     name: "Loot Survivor Devnet",
    //     chainId: "90013",
    //     baseUrl: "http://3.215.42.99:5050",
    //     rpcUrls: ["http://3.215.42.99:5050/rpc"],
    //   },
    // })
  };

  return handeleSwitchToDevnet;
};

interface MintEthProps {
  address: string;
}

export const mintEth = async ({ address }: MintEthProps) => {
  try {
    const requestBody = {
      address: address,
      key2: "10000000000000000000",
      // Add other data you want to send in the request body
    };

    const response = await fetch("http://http://3.215.42.99:5050/mint", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(requestBody),
    });

    const data = await response.json();

    // Check for a specific condition in the response to determine success
    if (response.ok && data.new_balance == "10000000000000000000") {
      console.log(data);
      return true;
    } else {
      console.error("Error in response:", data);
      return false;
    }
  } catch (error) {
    console.error("Error posting data:", error);
    return false;
  }
};
