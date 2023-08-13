"use client";

import { ApolloClient, ApolloProvider, InMemoryCache } from "@apollo/client";
import { StarknetConfig, useNetwork } from "@starknet-react/core";
import { useBurner } from "./lib/burner";
import { getGraphQLUrl } from "./lib/constants";
import { connectors } from "./lib/connectors";
import { useEffect, useState } from "react";

export default function Template({ children }: { children: React.ReactNode }) {
  const client = new ApolloClient({
    uri: getGraphQLUrl(),
    cache: new InMemoryCache({
      typePolicies: {
        Query: {
          fields: {
            // adventurers: {
            //   merge(existing = [], incoming) {
            //     const incomingTxHashes = new Set(
            //       incoming.map((i: any) => i.id)
            //     );
            //     const filteredExisting = existing.filter(
            //       (e: any) => !incomingTxHashes.has(e.id)
            //     );
            //     return [...filteredExisting, ...incoming];
            //   },
            // },
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
            beasts: {
              merge(existing = [], incoming) {
                const incomingKeys = new Set(
                  incoming.map((i: any) => `${i.adventurerId}-${i.seed}`)
                );
                const filteredExisting = existing.filter(
                  (e: any) => !incomingKeys.has(`${e.adventurerId}-${e.seed}`)
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

  const { arcadeAccounts } = useBurner();

  return (
    <StarknetConfig
      connectors={[...arcadeAccounts, ...connectors] as any}
      autoConnect
    >
      <ApolloProvider client={client}>{children}</ApolloProvider>
    </StarknetConfig>
  );
}
