import { useEffect, useCallback, useMemo } from "react";
import { useQuery } from "@apollo/client";
import { useQueriesStore, QueryKey } from "@/app/hooks/useQueryStore";
import { gameClient } from "@/app/lib/clients";
import { Network } from "@/app/hooks/useUIStore";
import { networkConfig } from "@/app/lib/networkConfig";

type Variables = Record<
  string,
  string | number | number[] | boolean | null | undefined | Date
>;

const useCustomQuery = (
  network: Network,
  queryKey: QueryKey,
  query: any,
  variables?: Variables,
  skip?: boolean
) => {
  const { setRefetch } = useQueriesStore((state) => ({
    setRefetch: state.setRefetch,
  }));

  // Memoize the Apollo Client instance based on clientType
  const client = useMemo(() => {
    return gameClient(networkConfig[network!].lsGQLURL);
  }, [network]);

  const { data, refetch } = useQuery(query, {
    client: client,
    variables: variables,
    skip: skip,
  });

  const refetchWrapper = useCallback(
    async (variables?: Variables) => {
      const { data: newData } = await refetch(variables);
      return newData;
    },
    [refetch]
  );

  useEffect(() => {
    setRefetch(queryKey, refetchWrapper);
  }, []);

  return data;
};

export default useCustomQuery;
