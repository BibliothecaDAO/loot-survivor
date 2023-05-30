import { useEffect, useMemo, useRef } from "react";
import { useQuery } from "@apollo/client";
import { useQueriesStore, QueryKey } from "./useQueryStore";
import { isEqual } from "lodash";

type Variables = Record<
  string,
  string | number | number[] | boolean | null | undefined
>;

const useCustomQuery = (
  queryKey: QueryKey,
  query: any,
  variables?: Variables,
  condition?: boolean
) => {
  const { updateData } = useQueriesStore();

  const skipQuery = useMemo(() => {
    // If condition is undefined, proceed with the query
    if (!condition) return false;

    // If condition exists, use it to determine whether to skip
    return condition;
  }, [variables, condition]);

  const { data, startPolling, stopPolling, loading, refetch } = useQuery(
    query,
    {
      variables: variables,
      skip: skipQuery,
      pollInterval: 5000,
    }
  );

  const refetchWrapper = async () => {
    try {
      await refetch();
    } catch (error) {
      console.error("Error refetching:", error);
    }
  };

  useEffect(() => {
    if (data) {
      updateData(queryKey, data, loading, refetchWrapper);
    }
  }, [data, updateData, loading, queryKey, refetchWrapper, variables]);

  useEffect(() => {
    startPolling(3000);
    return () => {
      stopPolling();
    };
  }, [startPolling, stopPolling]);
};

export default useCustomQuery;
