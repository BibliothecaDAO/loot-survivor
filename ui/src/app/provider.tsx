"use client";
import React from "react";
import { Connector, StarknetConfig, blastProvider } from "@starknet-react/core";
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
  const provider = onMainnet
    ? blastProvider({ apiKey })
    : blastProvider({ apiKey });
  const chains = onMainnet ? [mainnet] : [goerli];
  return (
    <StarknetConfig
      connectors={connectors}
      autoConnect
      provider={provider}
      chains={chains}
    >
      {children}
    </StarknetConfig>
  );
}
