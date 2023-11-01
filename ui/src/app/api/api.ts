interface MintEthProps {
  address: string;
}

export const getBlock = async (blockNumber: number) => {
  const rpcUrl = process.env.NEXT_PUBLIC_RPC_URL!;
  try {
    const requestBody = {
      jsonrpc: "2.0",
      method: "starknet_getBlockWithTxHashes",
      params: [{ block_number: blockNumber }],
      id: 1,
    };
    const response = await fetch(rpcUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(requestBody),
    });

    const data = await response.json();
    return data.result;
  } catch (error) {
    console.error("Error posting data:", error);
  }
};

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

export const getApibaraStatus = async () => {
  const response = await fetch(
    `https://zsvpqg33tc7n.statuspage.io/api/v2/status.json`
  );
  const data = await response.json();
  return data;
};
