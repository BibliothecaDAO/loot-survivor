"use client";
import { useBurner } from "@/app/lib/burner";
import { connectors } from "@/app/lib/connectors";
import { StarknetConfig, infuraProvider } from "@starknet-react/core";
import { getAPIKey } from "@/app/lib/constants";
import { goerli, mainnet } from "@starknet-react/chains";

export default function StarknetProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const { listConnectors } = useBurner();

  const apiKey = getAPIKey();
  return (
    <StarknetConfig
      connectors={[...listConnectors(), ...connectors]}
      autoConnect
      providers={[infuraProvider({ apiKey })]}
      chains={[goerli, mainnet]}
    >
      {children}
    </StarknetConfig>
  );
}
