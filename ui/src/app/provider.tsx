"use client";
import React from "react";
import {
  Connector,
  StarknetConfig,
  alchemyProvider,
  infuraProvider,
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
  const onMainnet = process.env.NEXT_PUBLIC_NETWORK === "mainnet";
  const providers = onMainnet
    ? [alchemyProvider({ apiKey })]
    : [infuraProvider({ apiKey })];
  const chains = onMainnet ? [mainnet] : [goerli];
  return (
    <StarknetConfig
      connectors={connectors}
      autoConnect
      providers={providers}
      chains={chains}
    >
      {children}
    </StarknetConfig>
  );
}
