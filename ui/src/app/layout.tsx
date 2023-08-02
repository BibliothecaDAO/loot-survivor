"use client";

import "./globals.css";
import { StarknetConfig } from "@starknet-react/core";
import { ApolloProvider, ApolloClient, InMemoryCache } from "@apollo/client";
import { connectors } from "./lib/connectors";
import { getGraphQLUrl } from "./lib/constants";
import { InjectedConnector } from "@starknet-react/core";
import { ArcadeConnector } from "./lib/arcade";
import { useBurner } from "./lib/burner";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const client = new ApolloClient({
    uri: getGraphQLUrl,
    cache: new InMemoryCache({
      typePolicies: {
        Query: {
          fields: {
            discoveries: {
              merge(existing = [], incoming) {
                const incomingTxHashes = new Set(
                  incoming.map((i: any) => i.txHash)
                );
                const filteredExisting = existing.filter(
                  (e: any) => !incomingTxHashes.has(e.txHash)
                );
                return [...filteredExisting, ...incoming];
              },
            },
            battles: {
              merge(existing = [], incoming) {
                const incomingTxHashes = new Set(
                  incoming.map((i: any) => i.txHash)
                );
                const filteredExisting = existing.filter(
                  (e: any) => !incomingTxHashes.has(e.txHash)
                );
                return [...filteredExisting, ...incoming];
              },
            },
            items: {
              merge(existing = [], incoming) {
                const incomingKeys = new Set(
                  incoming.map(
                    (i: any) => `${i.adventurerId}-${i.item}-${i.owner}`
                  )
                );
                const filteredExisting = existing.filter(
                  (e: any) =>
                    !incomingKeys.has(`${e.adventurerId}-${e.item}-${e.owner}`)
                );
                return [...filteredExisting, ...incoming];
              },
            },
          },
        },
      },
    }),
  });

  const { list, get } = useBurner();

  const arcadeAccounts = () => {
    const arcadeAccounts = [];
    const burners = list();

    for (const burner of burners) {
      const arcadeConnector = new ArcadeConnector(
        {
          options: {
            id: burner.address,
          },
        },
        get(burner.address)
      );

      arcadeAccounts.push(arcadeConnector);
    }

    return arcadeAccounts;
  };

  return (
    <html lang="en">
      <head>
        <title>Loot Survivors</title>
      </head>
      <body
        suppressHydrationWarning={true}
        className="text-terminal-green bg-conic-to-br to-terminal-black from-terminal-black bg-b bezel-container"
      >
        <img
          src="/crt_green_mask.png"
          alt="crt green mask"
          className="absolute w-full pointer-events-none crt-frame hidden sm:block"
        />
        <StarknetConfig
          connectors={[...connectors, ...arcadeAccounts()]}
          autoConnect
        >
          <ApolloProvider client={client}>{children}</ApolloProvider>
        </StarknetConfig>
      </body>
    </html>
  );
}
