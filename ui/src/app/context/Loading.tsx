import React, { createContext, useContext, useState } from "react";

export interface LoadingState {
  /** The connected guild object. */
  loading: boolean;
  setLoading: (value: boolean) => void;
}

const LOADING_INITIAL_STATE: LoadingState = {
  loading: false,
  setLoading: () => undefined,
};

const LoadingContext = createContext<LoadingState>(LOADING_INITIAL_STATE);

export function useLoading(): LoadingState {
  return useContext(LoadingContext);
}

export const useLoadingContext = () => {
  const [loading, setLoading] = useState<boolean>(false);

  return { loading, setLoading };
};

export function LoadingProvider({ children }: { children: React.ReactNode }) {
  const state = useLoadingContext();
  return (
    <LoadingContext.Provider value={state}>{children}</LoadingContext.Provider>
  );
}
