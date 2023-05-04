import { create } from "zustand";

type LoadingState = {
  loading: boolean;
  type: string;
  hash: string;
  pendingMessage: string;
  loadingData: any;
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
  updateData: (data: any) => void;
};

const useLoadingStore = create<LoadingState>((set, get) => ({
  loading: false,
  type: "",
  hash: "",
  pendingMessage: "",
  loadingData: "",
  notification: "",
  showNotification: false,
  notificationData: undefined,
  startLoading: (type, hash, pendingMessage, loadingData, notificationData) => {
    set({
      loading: true,
      type: type,
      hash,
      pendingMessage,
      loadingData,
      notificationData,
    });
  },
  stopLoading: (notificationData) => {
    set({ showNotification: true, notificationData: notificationData });
    setTimeout(
      () => set({ notificationData: "", showNotification: false }),
      5000
    );
    set({
      loading: false,
      pendingMessage: undefined,
      loadingData: "",
    });
  },
  updateData: (loadingData) => {
    set({ loadingData });
  },
}));

export default useLoadingStore;
