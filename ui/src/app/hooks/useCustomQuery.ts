import { useEffect, useCallback } from "react";
import { useQuery } from "@apollo/client";
import { useQueriesStore, QueryKey } from "./useQueryStore";

type Variables = Record<
  string,
  string | number | number[] | boolean | null | undefined | Date
>;

// type Queries = | AdventurerQuery | BattleQuery

const useCustomQuery = (
  queryKey: QueryKey,
  query: any,
  variables?: Variables,
  skip?: boolean
) => {
  const { setRefetch } = useQueriesStore((state) => ({
    setRefetch: state.setRefetch,
  }));

  const { data, loading, refetch, error } = useQuery(query, {
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
