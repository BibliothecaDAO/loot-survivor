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
  const { data: queryData, updateData, isDataUpdated } = useQueriesStore();

  const { data, startPolling, stopPolling, loading, refetch, error } = useQuery(
    query,
    {
      variables: variables,
      skip: !shouldPoll && shouldPoll !== undefined,
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
    if (shouldPoll || shouldPoll === undefined) {
      startPolling(5000);
    } else {
      stopPolling();
    }
  }, [startPolling, stopPolling]);
};

//   useEffect(() => {
//     startPolling(5000);
//     return () => {
//       stopPolling();
//     };
//   }, [startPolling, stopPolling]);
// };

export default useCustomQuery;
