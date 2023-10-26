"use client";
import React from "react";
import {
  Connector,
  StarknetConfig,
  // infuraProvider,
  alchemyProvider,
} from "@starknet-react/core";
import { goerli, mainnet } from "@starknet-react/chains";

export function StarknetProvider({
  connectors,
  children,
}: {
  connectors: Connector[];
  children: React.ReactNode;
}) {
  const apiKey = process.env.NEXT_PUBLIC_RPC_API_KEY!;
  console.log(apiKey);
  // const providers = [infuraProvider({ apiKey })]
  const providers = [alchemyProvider({ apiKey })];
  return (
    <StarknetConfig
      connectors={connectors}
      autoConnect
      providers={providers}
      chains={[goerli, mainnet]}
    >
      {children}
    </StarknetConfig>
  );
}
