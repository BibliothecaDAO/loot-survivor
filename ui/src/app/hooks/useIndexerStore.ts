import { create } from "zustand";
import { ApolloClient, InMemoryCache } from "@apollo/client";

type State = {
  indexer?: string;
  client: ApolloClient<any>;
  setIndexer: (value: string) => void;
};

const useIndexerStore = create<State>((set, get) => ({
  indexer: undefined,
  client: new ApolloClient({
    uri: "https://survivor-indexer.bibliothecadao.xyz:1/goerli-graphql",
    cache: new InMemoryCache(),
  }),
  setIndexer: (value) => {
    const newClient = new ApolloClient({
      uri: value,
      cache: new InMemoryCache(),
    });
    set({ indexer: value, client: newClient });
  },
}));

export default useIndexerStore;
