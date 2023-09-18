import { create } from "zustand";
import { ItemPurchase, UpgradeStats, ZeroUpgrade, u256 } from "../types";

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
  | "tutorial"
  | "create adventurer";

type State = {
  disconnected: boolean;
  setDisconnected: (value: boolean) => void;
  isWrongNetwork: boolean;
  setIsWrongNetwork: (value: boolean) => void;
  onboarded: boolean;
  handleOnboarded: () => void;
  isMuted: boolean;
  setIsMuted: (value: boolean) => void;
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
  potionAmount: number;
  setPotionAmount: (value: number) => void;
  upgrades: UpgradeStats;
  setUpgrades: (value: UpgradeStats) => void;
  slayAdventurers: string[];
  setSlayAdventurers: (value: string[]) => void;
  lastAction: Date | null;
  setLastAction: (value: Date | null) => void;
  mintAdventurer: boolean;
  setMintAdventurer: (value: boolean) => void;
  inventorySelected: number | null;
  setInventorySelected: (value: number) => void;
  upgradeScreen: number;
  setUpgradeScreen: (value: number) => void;
  startOption: string | null;
  setStartOption: (value: string) => void;
  arcadeDialog: boolean;
  showArcadeDialog: (value: boolean) => void;
  switchAdventurer: boolean;
  setSwitchAdventurer: (value: boolean) => void;
};

const useUIStore = create<State>((set) => ({
  disconnected: false,
  setDisconnected: (value) => set({ disconnected: value }),
  isWrongNetwork: false,
  setIsWrongNetwork: (value) => set({ isWrongNetwork: value }),
  onboarded: false,
  handleOnboarded: () => {
    set({ onboarded: true });
  },
  isMuted: false,
  setIsMuted: (value) => set({ isMuted: value }),
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
  potionAmount: 0,
  setPotionAmount: (value) => set({ potionAmount: value }),
  upgrades: { ...ZeroUpgrade },
  setUpgrades: (value) => set({ upgrades: value }),
  lastAction: null,
  slayAdventurers: [],
  setSlayAdventurers: (value) => set({ slayAdventurers: value }),
  setLastAction: (value) => set({ lastAction: value }),
  mintAdventurer: false,
  setMintAdventurer: (value) => set({ mintAdventurer: value }),
  inventorySelected: null,
  setInventorySelected: (value) => set({ inventorySelected: value }),
  upgradeScreen: 1,
  setUpgradeScreen: (value) => set({ upgradeScreen: value }),
  startOption: "",
  setStartOption: (value) => set({ startOption: value }),
  arcadeDialog: false,
  showArcadeDialog: (value) => set({ arcadeDialog: value }),
  switchAdventurer: false,
  setSwitchAdventurer: (value) => set({ switchAdventurer: value }),
}));

export default useUIStore;
