import { create } from "zustand";
import { QueryKey } from "./useQueryStore";

// TODO: Notification Data type

type LoadingState = {
  loading: boolean;
  type: string;
  hash: string;
  pendingMessage: string | string[];
  loadingQuery: QueryKey | null;
  showNotification: boolean;
  notificationData: any;
  adventurer: number | undefined;
  startLoading: (
    type: string,
    hash: string,
    pendingMessage: string | string[],
    data: any,
    adventurer: number | undefined,
    notificationData?: any
  ) => void;
  stopLoading: (notificationData?: any) => void;
};

const useLoadingStore = create<LoadingState>((set, get) => ({
  loading: false,
  type: "",
  hash: "",
  pendingMessage: "",
  loadingQuery: null,
  showNotification: false,
  notificationData: undefined,
  adventurer: undefined,
  startLoading: (
    type,
    hash,
    pendingMessage,
    loadingQuery,
    adventurer,
    notificationData
  ) => {
    set({
      loading: true,
      type: type,
      hash,
      pendingMessage,
      loadingQuery,
      adventurer,
      notificationData,
    });
  },
  stopLoading: (notificationData) => {
    set({
      showNotification: true,
      notificationData: notificationData || undefined,
      loading: false,
      pendingMessage: undefined,
      // loadingQuery: null,
      // hash: "",
    });
    setTimeout(
      () =>
        set({
          type: "",
          notificationData: undefined,
          showNotification: false,
          adventurer: undefined,
        }),
      5000
    );
  },
}));

export default useLoadingStore;
