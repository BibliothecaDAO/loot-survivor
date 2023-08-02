import { create } from "zustand";
import { ItemPurchase } from "../types";

export type ScreenPage =
  | "start"
  | "play"
  | "market"
  | "inventory"
  | "beast"
  | "leaderboard"
  | "upgrade"
  | "profile"
  | "encounters"
  | "guide"
  | "settings"
  | "player"
  | "wallet"
  | "tutorial";

type State = {
  connected: boolean;
  setConnected: (value: boolean) => void;
  onboarded: boolean;
  handleOnboarded: () => void;
  screen: ScreenPage;
  setScreen: (value: ScreenPage) => void;
  profile: number;
  setProfile: (value: number) => void;
  deathDialog: boolean;
  showDeathDialog: (value: boolean) => void;
  tutorialDialog: boolean;
  showTutorialDialog: (value: boolean) => void;
  displayHistory: boolean;
  setDisplayHistory: (value: boolean) => void;
  displayCart: boolean;
  setDisplayCart: (value: boolean) => void;
  equipItems: string[];
  setEquipItems: (value: string[]) => void;
  dropItems: string[];
  setDropItems: (value: string[]) => void;
  purchaseItems: ItemPurchase[];
  setPurchaseItems: (value: ItemPurchase[]) => void;
  upgradeStats: string[];
  setUpgradeStats: (value: string[]) => void;
  lastAction: Date | null;
  setLastAction: (value: Date | null) => void;
  mintAdventurer: boolean;
  setMintAdventurer: (value: boolean) => void;
  inventorySelected: number | null;
  setInventorySelected: (value: number) => void;
  arcadeDialog: boolean;
  showArcadeDialog: (value: boolean) => void;
  
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
  deathDialog: false,
  showDeathDialog: (value) => set({ deathDialog: value }),
  tutorialDialog: false,
  showTutorialDialog: (value) => set({ tutorialDialog: value }),
  displayHistory: false,
  setDisplayHistory: (value) => set({ displayHistory: value }),
  displayCart: false,
  setDisplayCart: (value) => set({ displayCart: value }),
  equipItems: [],
  setEquipItems: (value) => set({ equipItems: value }),
  dropItems: [],
  setDropItems: (value) => set({ dropItems: value }),
  purchaseItems: [],
  setPurchaseItems: (value) => set({ purchaseItems: value }),
  upgradeStats: [],
  setUpgradeStats: (value) => set({ upgradeStats: value }),
  lastAction: null,
  setLastAction: (value) => set({ lastAction: value }),
  mintAdventurer: false,
  setMintAdventurer: (value) => set({ mintAdventurer: value }),
  inventorySelected: null,
  setInventorySelected: (value) => set({ inventorySelected: value }),
  arcadeDialog: false,
  showArcadeDialog: (value) => set({ arcadeDialog: value }),
}));

export default useUIStore;
