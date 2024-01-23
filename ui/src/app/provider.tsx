"use client";
import React from "react";
import {
  Connector,
  StarknetConfig,
  alchemyProvider,
  blastProvider,
  publicProvider,
} from "@starknet-react/core";
import { goerli, mainnet, sepolia } from "@starknet-react/chains";

export function StarknetProvider({
  connectors,
  children,
}: {
  connectors: Connector[];
  children: React.ReactNode;
}) {
  const apiKey = process.env.NEXT_PUBLIC_RPC_API_KEY!;
  const onMainnet = process.env.NEXT_PUBLIC_NETWORK === "mainnet";
  const onSepolia = process.env.NEXT_PUBLIC_NETWORK === "sepolia";
  const provider = onMainnet
    ? alchemyProvider({ apiKey })
    : blastProvider({ apiKey });
  const chains = onMainnet ? [mainnet] : onSepolia ? [sepolia] : [goerli];
  return (
    <StarknetConfig
      connectors={connectors}
      autoConnect
      provider={publicProvider()}
      chains={chains}
    >
      {children}
    </StarknetConfig>
  );
}
