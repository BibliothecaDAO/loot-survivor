import React, { createContext, useContext, useState } from "react";

export interface UIState {
  onboarded: boolean | undefined;
  setOnboarded: (value: any) => void;
}

const UI_INITIAL_STATE: UIState = {
  onboarded: undefined,
  setOnboarded: () => undefined,
};

const UIContext = createContext<UIState>(UI_INITIAL_STATE);

export function useUI(): UIState {
  return useContext(UIContext);
}

export const useUIContext = () => {
  const [onboarded, setOnboarded] = useState<boolean | undefined>(undefined);

  return {
    onboarded,
    setOnboarded,
  };
};

export function UIProvider({ children }: { children: React.ReactNode }) {
  const state = useUIContext();
  return <UIContext.Provider value={state}>{children}</UIContext.Provider>;
}
