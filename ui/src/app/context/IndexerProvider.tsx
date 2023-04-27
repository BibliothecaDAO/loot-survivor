import React, { createContext, useContext, useEffect, useState } from "react";
import { ApolloClient, InMemoryCache, ApolloProvider } from "@apollo/client";

export interface IndexerState {
  indexer: string | undefined;
  setIndexer: (value: any) => void;
}

const INDEXER_INITIAL_STATE: IndexerState = {
  indexer: undefined,
  setIndexer: () => undefined,
};

const IndexerContext = createContext<IndexerState>(INDEXER_INITIAL_STATE);

export function useIndexer(): IndexerState {
  return useContext(IndexerContext);
}

export const useIndexerContext = () => {
  const [indexer, setIndexer] = useState<string | undefined>(undefined);
  const [client, setClient] = useState<any>(
    new ApolloClient({
      uri: "http://survivor-indexer.bibliothecadao.xyz:8080/goerli-graphql",
      cache: new InMemoryCache(),
    })
  );

  useEffect(() => {
    setClient(
      new ApolloClient({
        uri: indexer,
        cache: new InMemoryCache(),
      })
    );
  }, [indexer]);

  // const client = new ApolloClient({
  //   uri: indexer,
  //   cache: new InMemoryCache(),
  // });

  return {
    indexer,
    setIndexer,
    client,
  };
};

export function IndexerProvider({ children }: { children: React.ReactNode }) {
  const state = useIndexerContext();
  return (
    <ApolloProvider client={state.client}>
      <IndexerContext.Provider value={state}>
        {children}
      </IndexerContext.Provider>
    </ApolloProvider>
  );
}
