import { use, useEffect, useMemo, useRef, useCallback } from "react";
import { useQuery } from "@apollo/client";
import { useQueriesStore, QueryKey } from "./useQueryStore";
import { AdventurerQuery, BattleQuery, ItemQuery } from "./graphql/types";
import { isEqual } from "lodash";

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
  const { updateData } = useQueriesStore();

  const { data, loading, refetch, error } = useQuery(query, {
    variables: variables,
    skip: skip,
  });

  const refetchWrapper = useCallback(async () => {
    try {
      await refetch();
    } catch (error) {
      console.error("Error refetching:", error);
      throw error;
    }
  }, [refetch]);

  const prevVariablesRef = useRef<Variables>();

  useEffect(() => {
    console.log(variables);
    console.log(queryKey, data, loading, error);
    if (data) {
      updateData(queryKey, data, loading, refetchWrapper);
    }
    prevVariablesRef.current = variables;
  }, [data, variables]);
};

export default useCustomQuery;
