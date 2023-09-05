"use client";

import { BurnerProvider } from "./context";
import { useBurner } from "./lib/burner";
import { connectors } from "./lib/connectors";
import { StarknetConfig } from "@starknet-react/core";

export default function Template({ children }: { children: React.ReactNode }) {
  const { listConnectors } = useBurner();

  return (
    <StarknetConfig
      connectors={[...listConnectors(), ...connectors]}
      autoConnect
    >
      <BurnerProvider>
        {children}
      </BurnerProvider>
    </StarknetConfig>
  );
}
