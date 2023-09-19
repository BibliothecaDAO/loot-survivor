import { create } from "zustand";
import { QueryKey } from "./useQueryStore";

// TODO: Notification Data type

type LoadingState = {
  loading: boolean;
  type: string;
  hash: string;
  txAccepted: boolean;
  pendingMessage: string | string[];
  showNotification: boolean;
  notificationData: any;
  error: boolean;
  errorMessage: string | undefined;
  adventurer: number | undefined;
  history: any[];
  startLoading: (
    type: string,
    pendingMessage: string | string[],
    data: any,
    adventurer: number | undefined
  ) => void;
  resetNotification: () => void;
  setTxHash: (hash: string) => void;
  setTxAccepted: (txAccepted: boolean) => void;
  stopLoading: (notificationData: any, error?: boolean) => void;
  deathMessage: any;
  setDeathMessage: (deathMessage: any) => void;
};

const useLoadingStore = create<LoadingState>((set, get) => ({
  loading: false,
  type: "",
  hash: "",
  txAccepted: false,
  pendingMessage: "",
  loadingQuery: null,
  showNotification: false,
  notificationData: undefined,
  error: false,
  errorMessage: undefined,
  adventurer: undefined,
  history: [],
  startLoading: (type, pendingMessage, loadingQuery, adventurer) => {
    set({
      loading: true,
      type: type,
      pendingMessage,
      adventurer,
    });
  },
  setTxHash: (hash) => set({ hash }),
  setTxAccepted: (txAccepted) => set({ txAccepted }),
  stopLoading: (notificationData, error) => {
    set({
      showNotification: notificationData ? true : false,
      notificationData: notificationData || undefined,
      error: error ?? false,
      errorMessage: error ? notificationData.message : undefined,
      loading: false,
      pendingMessage: undefined,
      history: [
        ...get().history,
        {
          hash: get().hash,
          type: get().type,
          notificationData: notificationData,
        },
      ],
      hash: "",
      adventurer: undefined,
      txAccepted: false,
    });
  },
  resetNotification: () =>
    set({
      type: "",
      notificationData: undefined,
      error: false,
      errorMessage: undefined,
      showNotification: false,
    }),
  deathMessage: null,
  setDeathMessage: (deathMessage) => {
    set({ deathMessage });
  },
}));

export default useLoadingStore;
