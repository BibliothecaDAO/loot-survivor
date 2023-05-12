import { create } from "zustand";

export type ScreenPage =
  | "start"
  | "actions"
  | "market"
  | "inventory"
  | "beast"
  | "leaderboard"
  | "upgrade"
  | "profile";

export type Dialog = "death" | "beast";

type State = {
  connected: boolean;
  setConnected: (value: boolean) => void;
  onboarded: boolean;
  handleOnboarded: () => void;
  screen: ScreenPage;
  setScreen: (value: ScreenPage) => void;
  profile: number;
  setProfile: (value: number) => void;
  dialog: Dialog | null;
  showDialog: (value: Dialog | null) => void;
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
  dialog: null,
  showDialog: (value) => set({ dialog: value }),
}));

export default useUIStore;
