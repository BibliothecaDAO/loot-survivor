export const getItems = async (rpcUrl: string, gameAddress: string) => {
  const response = await fetch(rpcUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: "starknet_call",
      params: [
        {
          contract_address: gameAddress,
          entry_point_selector:
            "0xb0d944377304e5d17e57a0404b4c1714845736851cfe18cc171a33868091be", // get_marketplace_items
          calldata: [],
        },
        "pending",
      ],
      id: 0,
    }),
  });

  const data = await response.json();

  if (response.ok) {
    console.log("Interface fetched successfully");
  } else {
    console.error("Error in response:", data);
  }

  return data;
};
