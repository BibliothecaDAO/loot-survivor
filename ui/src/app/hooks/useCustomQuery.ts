import { useEffect } from "react";
import { useQuery } from "@apollo/client";
import { useQueriesStore, QueryKey } from "./useQueryStore";

type Variables = Record<
  string,
  string | number | number[] | boolean | null | undefined
>;

const useCustomQuery = (
  queryKey: QueryKey,
  query: any,
  variables?: Variables
) => {
  const { updateData } = useQueriesStore();
  const { data, startPolling, stopPolling, loading, refetch } = useQuery(
    query,
    {
      variables,
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
    startPolling(5000);
    return () => {
      stopPolling();
    };
  }, [startPolling, stopPolling]);
};

export default useCustomQuery;
