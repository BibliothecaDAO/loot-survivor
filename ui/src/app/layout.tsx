"use client";
import "./globals.css";
import { InjectedConnector, StarknetConfig } from "@starknet-react/core";
import ControllerConnector from "@cartridge/connector";
import { contracts } from "./hooks/useContracts";
import useIndexerStore from "./hooks/useIndexerStore";
import { ApolloProvider } from "@apollo/client";

// NOT WORKING PROPERLY
const controllerConnector = new ControllerConnector([
  {
    target: contracts.goerli.lords_erc20_mintable,
    method: "mint",
  },
  {
    target: contracts.goerli.lords_erc20_mintable,
    method: "approve",
  },
  {
    target: contracts.goerli.adventurer,
    method: "mint_with_starting_weapon",
  },
]);

export const argentConnector = new InjectedConnector({
  options: {
    id: "argentX",
  },
});

export const connectors = [controllerConnector as any, argentConnector];


export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const client = useIndexerStore((state) => state.client);

  return (
    <html lang="en">
      <head>
        <title>Loot Survivors</title>
      </head>
      <body suppressHydrationWarning={true} className="text-terminal-green bg-conic-to-br to-terminal-black from-terminal-black bg-b bezel-container">
        <img
          src="/crt_green_mask.png"
          className="absolute w-full pointer-events-none crt-frame"
        />
        <StarknetConfig connectors={connectors} autoConnect>
          <ApolloProvider client={client}>{children}</ApolloProvider>
        </StarknetConfig>
      </body>
    </html>
  );
}
