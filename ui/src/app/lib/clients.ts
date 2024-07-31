import { ApolloClient, InMemoryCache } from "@apollo/client";
// import { setContext } from "@apollo/client/link/context";
// import { Network } from "@/app/hooks/useUIStore";

// const createAuthLink = () =>
//   setContext((_, { headers }) => {
//     return {
//       headers: {
//         ...headers,
//         "Cache-Control": "no-cache, no-store, must-revalidate",
//         Pragma: "no-cache",
//         Expires: "0",
//       },
//     };
//   });

export const goldenTokenClient = (GQLUrl: string) => {
  return new ApolloClient({
    uri: GQLUrl,
    defaultOptions: {
      watchQuery: {
        fetchPolicy: "no-cache",
        nextFetchPolicy: "no-cache",
      },
      query: {
        fetchPolicy: "no-cache",
      },
      mutate: {
        fetchPolicy: "no-cache",
      },
    },
    cache: new InMemoryCache({
      addTypename: false,
    }),
  });
};

export const gameClient = (GQLUrl: string) => {
  // const httpLink = createHttpLink({
  //   uri: `/api/graphql-proxy?api=${network}`,
  //   fetchOptions: {
  //     next: { revalidate: 0 },
  //     cache: "no-store",
  //   },
  // });

  // const authLink = createAuthLink();

  return new ApolloClient({
    uri: GQLUrl,
    defaultOptions: {
      watchQuery: {
        fetchPolicy: "no-cache",
        nextFetchPolicy: "no-cache",
      },
      query: {
        fetchPolicy: "no-cache",
      },
      mutate: {
        fetchPolicy: "no-cache",
      },
    },
    cache: new InMemoryCache({
      addTypename: false,
    }),
  });
};
