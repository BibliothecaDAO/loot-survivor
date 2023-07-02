import { create } from "zustand";

export type ScreenPage =
  | "start"
  | "actions"
  | "market"
  | "inventory"
  | "beast"
  | "leaderboard"
  | "upgrade"
  | "profile"
  | "encounters"
  | "guide"
  | "settings"
  | "player";

type State = {
  connected: boolean;
  setConnected: (value: boolean) => void;
  onboarded: boolean;
  handleOnboarded: () => void;
  screen: ScreenPage;
  setScreen: (value: ScreenPage) => void;
  profile: number;
  setProfile: (value: number) => void;
  dialog: boolean;
  showDialog: (value: boolean) => void;
  displayHistory: boolean;
  setDisplayHistory: (value: boolean) => void;
  displayCart: boolean;
  setDisplayCart: (value: boolean) => void;
  purchasedItem: boolean;
  setPurchasedItem: (value: boolean) => void;
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
  profile: 0,
  setProfile: (value) => set({ profile: value }),
  dialog: false,
  showDialog: (value) => set({ dialog: value }),
  displayHistory: false,
  setDisplayHistory: (value) => set({ displayHistory: value }),
  displayCart: false,
  setDisplayCart: (value) => set({ displayCart: value }),
  purchasedItem: false,
  setPurchasedItem: (value) => set({ purchasedItem: value }),
}));

export default useUIStore;
