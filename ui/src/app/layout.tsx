"use client";
import "./globals.css";
import {
  InjectedConnector,
  StarknetConfig,
} from "@starknet-react/core";
import ControllerConnector from "@cartridge/connector";
import { useMemo } from "react";
import { AdventurerProvider } from "./context/AdventurerProvider";
import { TransactionCartProvider } from "./context/TransactionCartProvider";
import { UIProvider } from "./context/UIProvider";
import { IndexerProvider } from "./context/IndexerProvider";
import { contracts } from "./hooks/useContracts";

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

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {

  const connectors = useMemo(
    () => [
      new InjectedConnector({ options: { id: "argentX" } }),
      new InjectedConnector({ options: { id: "braavos" } }),
      // controllerConnector as any,
      // new InjectedConnector({ options: { id: "guildly" } }),
    ],
    []
  );

  return (
    <html lang="en">
      <head>
        <title>Loot Survivors</title>
      </head>
      <body className=" text-terminal-green bg-conic-to-br to-black from-terminal-black bg-b bezel-container" >
        <IndexerProvider>
          <StarknetConfig connectors={connectors} autoConnect>
            <UIProvider>
              <TransactionCartProvider>
                <AdventurerProvider>{children}</AdventurerProvider>
              </TransactionCartProvider>
            </UIProvider>
          </StarknetConfig>
        </IndexerProvider>
      </body>
    </html>
  );
}
