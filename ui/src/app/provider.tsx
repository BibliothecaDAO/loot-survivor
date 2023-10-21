"use client";
import React from "react";
import {
  Connector,
  StarknetConfig,
  infuraProvider,
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
  const apiKey = getAPIKey();
  return (
    <StarknetConfig
      connectors={connectors}
      autoConnect
      providers={[infuraProvider({ apiKey })]}
      chains={[goerli, mainnet]}
    >
      {children}
    </StarknetConfig>
  );
}
