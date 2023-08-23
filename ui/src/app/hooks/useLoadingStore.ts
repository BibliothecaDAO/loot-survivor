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
  adventurer: number | undefined;
  history: any[];
  startLoading: (
    type: string,
    pendingMessage: string | string[],
    data: any,
    adventurer: number | undefined,
    notificationData?: any
  ) => void;
  resetNotification: () => void;
  setTxHash: (hash: string) => void;
  setTxAccepted: (txAccepted: boolean) => void;
  stopLoading: (notificationData?: any) => void;
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
  adventurer: undefined,
  history: [],
  startLoading: (
    type,
    pendingMessage,
    loadingQuery,
    adventurer,
    notificationData
  ) => {
    set({
      loading: true,
      type: type,
      pendingMessage,
      adventurer,
      notificationData,
    });
  },
  setTxHash: (hash) => set({ hash }),
  setTxAccepted: (txAccepted) => set({ txAccepted }),
  stopLoading: (notificationData) => {
    set({
      showNotification: notificationData ? true : false,
      notificationData: notificationData || undefined,
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
    });
  },
  resetNotification: () =>
    set({
      type: "",
      notificationData: undefined,
      showNotification: false,
    }),
  deathMessage: null,
  setDeathMessage: (deathMessage) => {
    set({ deathMessage });
  },
}));

export default useLoadingStore;
