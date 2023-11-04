import { ApolloClient, InMemoryCache } from "@apollo/client";

export const goldenTokenClient = new ApolloClient({
  uri: process.env.NEXT_PUBLIC_TOKENS_GQL_URL,
  cache: new InMemoryCache({
    typePolicies: {
      Query: {
        fields: {
          getERC721Tokens: {
            merge(existing = [], incoming) {
              const incomingTokenIds = new Set(
                incoming.map((i: any) => i.token_id)
              );
              const filteredExisting = existing.filter(
                (e: any) => !incomingTokenIds.has(e.token_id)
              );
              return [...filteredExisting, ...incoming];
            },
          },
        },
      },
    },
  }),
});

export const gameClient = new ApolloClient({
  uri: process.env.NEXT_PUBLIC_LS_GQL_URL,
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
