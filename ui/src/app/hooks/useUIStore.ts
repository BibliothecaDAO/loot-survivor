import { create } from "zustand";

export type ScreenPage =
  | "start"
  | "actions"
  | "market"
  | "inventory"
  | "beast"
  | "leaderboard"
  | "upgrade";

type State = {
  connected: boolean;
  setConnected: (value: boolean) => void;
  onboarded: boolean;
  handleOnboarded: () => void;
  screen: ScreenPage;
  setScreen: (value: ScreenPage) => void;
};

const useUIStore = create<State>((set) => ({
  connected: false,
  setConnected: (value) => set({ connected: value }),
  onboarded: false,
  handleOnboarded: () => {
    set({ onboarded: true });
  },
  screen: "start",
  setScreen: (value) => set({ screen: value }),
}));

export default useUIStore;
