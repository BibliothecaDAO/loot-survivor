"use client";

import { Provider } from "starknet";
import { useBurner } from "./lib/burner";
import { connectors } from "./lib/connectors";
import { StarknetConfig } from "@starknet-react/core";
import { getRPCUrl } from "./lib/constants";

export default function Template({ children }: { children: React.ReactNode }) {
  const { listConnectors } = useBurner();

  const rpc_addr = getRPCUrl();

  const provider = new Provider({
    rpc: { nodeUrl: rpc_addr! },
    sequencer: { baseUrl: rpc_addr! },
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
