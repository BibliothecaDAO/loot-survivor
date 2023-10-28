import { ApolloClient, InMemoryCache } from "@apollo/client";
import { getGraphQLUrl } from "@/app/lib/constants";

export const goldenTokenClient = new ApolloClient({
  uri: "https://realmsworld-git-ls-updates-loot-bibliotheca.vercel.app/api/graphql",
  cache: new InMemoryCache(),
});

export const gameClient = new ApolloClient({
  uri: getGraphQLUrl(),
  cache: new InMemoryCache({
    typePolicies: {
      Query: {
        fields: {
          adventurers: {
            merge(existing = [], incoming) {
              const incomingTxHashes = new Set(incoming.map((i: any) => i.id));
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
