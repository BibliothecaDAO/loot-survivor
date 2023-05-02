import { create } from "zustand";

type State = {
  onboarded?: boolean;
  setOnboarded: (value: boolean) => void;
};

const useUIStore = create<State>((set) => ({
  onboarded: undefined,
  setOnboarded: (value) => set({ onboarded: value }),
}));

export default useUIStore;
