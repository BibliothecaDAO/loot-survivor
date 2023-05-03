import { useEffect } from "react";
import usePrevious from "use-previous";
import useLoadingStore from "./useLoadingStore";

export interface UseLoaderProps {
  data?: any;
}

export const useLoader = ({ data }: UseLoaderProps) => {
  const loading = useLoadingStore((state) => state.loading);
  const stopLoading = useLoadingStore((state) => state.stopLoading);
  const prevData = usePrevious(data);

  useEffect(() => {
    if (data && prevData && JSON.stringify(data) !== JSON.stringify(prevData)) {
      stopLoading();
    }
  }, [loading, data, prevData, stopLoading]);
};
