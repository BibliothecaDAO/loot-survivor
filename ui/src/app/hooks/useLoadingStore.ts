import { create } from "zustand";
import { QueryKey } from "./useQueryStore";

type LoadingState = {
  loading: boolean;
  type: string;
  hash: string;
  pendingMessage: string;
  loadingQuery: QueryKey | null;
  showNotification: boolean;
  notificationData: any;
  startLoading: (
    type: string,
    hash: string,
    pendingMessage: string,
    data: any,
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
  notification: "",
  showNotification: false,
  notificationData: undefined,
  startLoading: (
    type,
    hash,
    pendingMessage,
    loadingQuery,
    notificationData
  ) => {
    set({
      loading: true,
      type: type,
      hash,
      pendingMessage,
      loadingQuery,
      notificationData,
    });
  },
  stopLoading: (notificationData) => {
    set({ showNotification: true, notificationData: notificationData });
    setTimeout(
      () =>
        set({ type: "", notificationData: undefined, showNotification: false }),
      5000
    );
    set({
      loading: false,
      pendingMessage: undefined,
      loadingQuery: null,
    });
  },
}));

export default useLoadingStore;
