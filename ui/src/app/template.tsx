"use client";

import { BurnerProvider } from "./context";
// import { useBurner } from "@dojoengine/create-burner";
import { useBurner } from "./lib/burner";
import { connectors } from "./lib/connectors";
import { StarknetConfig } from "@starknet-react/core";
import { Account, RpcProvider } from "starknet";
import { useMemo } from "react";

export default function Template({ children }: { children: React.ReactNode }) {

  const provider = useMemo(() => new RpcProvider({
    nodeUrl: 'https://starknet-goerli.infura.io/v3/6c536e8272f84d3ba63bf9f248c5e128'
  }), []);

  const masterAddress = process.env.NEXT_PUBLIC_ADMIN_ADDRESS!;
  const privateKey = process.env.NEXT_PUBLIC_ADMIN_PRIVATE_KEY!;
  const masterAccount = useMemo(() => new Account(provider, masterAddress, privateKey), [provider, masterAddress, privateKey]);


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
