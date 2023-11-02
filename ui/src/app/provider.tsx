"use client";
import React from "react";
import {
  Connector,
  StarknetConfig,
  infuraProvider,
} from "@starknet-react/core";
import { goerli } from "@starknet-react/chains";

export function StarknetProvider({
  connectors,
  children,
}: {
  connectors: Connector[];
  children: React.ReactNode;
}) {
  const apiKey = process.env.NEXT_PUBLIC_RPC_API_KEY!;
  const providers = [infuraProvider({ apiKey })];
  return (
    <StarknetConfig
      connectors={connectors}
      autoConnect
      providers={providers}
      chains={[goerli]}
    >
      {children}
    </StarknetConfig>
  );
}
