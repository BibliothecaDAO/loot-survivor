import { create } from "zustand";

type State = {
  connected?: boolean;
  setConnected: (value: boolean) => void;
};

const useUIStore = create<State>((set) => ({
  connected: undefined,
  setConnected: (value) => set({ connected: value }),
}));

export default useUIStore;
