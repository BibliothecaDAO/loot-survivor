"use client";
import React from "react";
import {
  Connector,
  StarknetConfig,
  // infuraProvider,
  alchemyProvider,
} from "@starknet-react/core";
import { goerli, mainnet } from "@starknet-react/chains";
import { getAPIKey } from "@/app/lib/constants";

export default function StarknetProvider({
  connectors,
  children,
}: {
  connectors: Connector[];
  children: React.ReactNode;
}) {
  const apiKey = getAPIKey()!;
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
