import { useEffect, useMemo, useRef } from "react";
import { useQuery } from "@apollo/client";
import { useQueriesStore, QueryKey } from "./useQueryStore";
import { cond, isEqual } from "lodash";

type Variables = Record<
  string,
  string | number | number[] | boolean | null | undefined
>;

const useCustomQuery = (
  queryKey: QueryKey,
  query: any,
  variables?: Variables,
  shouldPoll?: boolean
) => {
  const { updateData } = useQueriesStore();

  const skipQuery = useMemo(() => {
    // If condition is undefined, proceed with the query
    if (!shouldPoll) return false;

    // If condition exists, use it to determine whether to skip
    return shouldPoll;
  }, [variables, shouldPoll]);

  const { data, startPolling, stopPolling, loading, refetch, error } = useQuery(
    query,
    {
      variables: variables,
      skip: skipQuery,
    }
  );

  console.log(shouldPoll);
  console.log(variables);

  console.log(data);

  console.log(`Error: ${error}`);

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
    if (shouldPoll) {
      startPolling(5000);
    } else {
      stopPolling();
    }
  }, [shouldPoll, startPolling, stopPolling]);
};

export default useCustomQuery;
