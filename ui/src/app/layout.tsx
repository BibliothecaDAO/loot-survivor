"use client";

import { ApolloClient, ApolloProvider, InMemoryCache } from "@apollo/client";
import { getGraphQLUrl } from "./lib/constants";

import "./globals.css";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const client = new ApolloClient({
    uri: getGraphQLUrl(),
    cache: new InMemoryCache({
      typePolicies: {
        Query: {
          fields: {
            adventurers: {
              merge(existing = [], incoming) {
                const incomingTxHashes = new Set(
                  incoming.map((i: any) => i.id)
                );
                const filteredExisting = existing.filter(
                  (e: any) => !incomingTxHashes.has(e.id)
                );
                return [...filteredExisting, ...incoming];
              },
            },
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
  return (
    <html lang="en">
      <body
        suppressHydrationWarning={true}
        className="min-h-screen overflow-hidden text-terminal-green bg-conic-to-br to-terminal-black from-terminal-black bezel-container"
      >
        <img
          src="/crt_green_mask.png"
          alt="crt green mask"
          className="absolute w-full pointer-events-none crt-frame hidden sm:block"
        />
        <ApolloProvider client={client}>{children}</ApolloProvider>
      </body>
    </html>
  );
}
