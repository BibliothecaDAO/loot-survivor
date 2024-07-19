"use client";
import React from "react";
import {
  StarknetConfig,
  starkscan,
  jsonRpcProvider,
} from "@starknet-react/core";
import { mainnet, sepolia } from "@starknet-react/chains";
import { Chain } from "@starknet-react/chains";
import { connectors } from "@/app/lib/connectors";
import { networkConfig } from "./lib/networkConfig";
import { Network } from "./hooks/useUIStore";

export function StarknetProvider({
  children,
  network,
}: {
  children: React.ReactNode;
  network: Network;
}) {
  function rpc(_chain: Chain) {
    return {
      nodeUrl: networkConfig[network!].rpcUrl,
    };
  }

  return (
    <StarknetConfig
      autoConnect={
        network === "mainnet" || network === "sepolia" ? true : false
      }
      chains={network == "mainnet" ? [mainnet] : [sepolia]}
      connectors={connectors(
        networkConfig[network!].gameAddress,
        networkConfig[network!].lordsAddress,
        network
      )}
      explorer={starkscan}
      provider={jsonRpcProvider({ rpc })}
    >
      {children}
    </StarknetConfig>
  );
}
