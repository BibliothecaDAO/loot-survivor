import { shortString } from "starknet";

export const fetchBeastImage = async (
  beastsAddress: string,
  tokenId: number
) => {
  const response = await fetch("/api/rpc-proxy", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: "starknet_call",
      params: [
        {
          contract_address: beastsAddress,
          entry_point_selector:
            "0x012a7823b0c6bee58f8c694888f32f862c6584caa8afa0242de046d298ba684d", // tokenURI
          calldata: [tokenId.toString(16), "0x0"],
        },
        "pending",
      ],
      id: 0,
    }),
  });

  const data = await response.json();

  if (response.ok) {
    console.log("Beast fetched successfully");
  } else {
    console.error("Error in response:", data);
  }

  const value: string[] = [];
  for (let i = 2; i < data.result?.length; i++) {
    let result = shortString.decodeShortString(data.result[i]);
    value.push(result);
  }

  const jsonString = value.join("");
  const regex = new RegExp("\\u0015", "g");
  const modifiedJsonString = jsonString
    .replace(
      /"name":"(.*?)"\,/g,
      (match: any, name: any) => `"name":"${name.replaceAll('"', '\\"')}",`
    )
    .replace(regex, "");

  const parsedJson = JSON.parse(modifiedJsonString);

  return parsedJson.image;
};
