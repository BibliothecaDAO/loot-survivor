import { use, useEffect, useMemo, useRef, useCallback } from "react";
import { useQuery } from "@apollo/client";
import { useQueriesStore, QueryKey } from "./useQueryStore";
import { AdventurerQuery, BattleQuery, ItemQuery } from "./graphql/types";

type Variables = Record<
  string,
  string | number | number[] | boolean | null | undefined | Date
>;

// type Queries = | AdventurerQuery | BattleQuery

const useCustomQuery = (
  queryKey: QueryKey,
  query: any,
  variables?: Variables,
  shouldPoll?: boolean,
  skip?: boolean
) => {
  const previousData = useRef();
  const { updateData } = useQueriesStore();

  const { data, startPolling, stopPolling, loading, refetch, error } = useQuery(
    query,
    {
      variables: variables,
      skip: skip,
    }
  );

  const refetchWrapper = useCallback(async () => {
    try {
      await refetch();
    } catch (error) {
      console.error("Error refetching:", error);
      throw error;
    }
  }, [refetch]);

  if (data && previousData.current !== data) {
    updateData(queryKey, data, loading, refetchWrapper);
    previousData.current = data;
  }

  useEffect(() => {
    if (shouldPoll) {
      startPolling(5000);
    } else {
      stopPolling();
    }
  }, [shouldPoll, startPolling, stopPolling]);
};

export default useCustomQuery;
