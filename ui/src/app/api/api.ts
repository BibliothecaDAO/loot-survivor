import { useAccount } from "@starknet-react/core";

interface MintEthProps {
  address: string;
}

export const mintEth = async ({ address }: MintEthProps) => {
  try {
    const requestBody = {
      address: address,
      amount: 10000000000000000000,
      // Add other data you want to send in the request body
    };

    const response = await fetch(
      "https://survivor-indexer.bibliothecadao.xyz/mint",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(requestBody),
      }
    );

    const data = await response.json();

    // Check for a specific condition in the response to determine success
    if (response.ok) {
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
