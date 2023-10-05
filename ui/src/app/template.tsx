"use client";

import { Provider } from "starknet";
import { useBurner } from "./lib/burner";
import { connectors } from "./lib/connectors";
import { StarknetConfig } from "@starknet-react/core";
import { mainnet_addr } from "./lib/constants";

export default function Template({ children }: { children: React.ReactNode }) {
  const { listConnectors } = useBurner();

  const provider = new Provider({
    rpc: { nodeUrl: mainnet_addr },
    sequencer: { baseUrl: mainnet_addr },
  });

  return (
    <StarknetConfig
      connectors={[...listConnectors(), ...connectors]}
      autoConnect
      defaultProvider={provider}
    >
      {children}
    </StarknetConfig>
  );
}
