import { create } from "zustand";

type LoadingState = {
  loading: boolean;
  type: string;
  hash: string;
  pendingMessage: string;
  data: any;
  startLoading: (
    type: string,
    hash: string,
    pendingMessage: string,
    data: any
  ) => void;
  stopLoading: () => void;
  updateData: (data: any) => void;
};

const useLoadingStore = create<LoadingState>((set) => ({
  loading: false,
  type: "",
  hash: "",
  pendingMessage: "",
  data: "",
  startLoading: (type, hash, pendingMessage, data) => {
    set({
      loading: true,
      type: type,
      hash,
      pendingMessage,
      data,
    });
  },
  stopLoading: () => {
    set({
      loading: false,
      pendingMessage: undefined,
      data: "",
    });
  },
  updateData: (data) => {
    set({ data });
  },
}));

export default useLoadingStore;
