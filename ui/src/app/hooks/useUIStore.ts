import { create } from "zustand";
import {
  ItemPurchase,
  UpgradeStats,
  ZeroUpgrade,
  SpecialBeast,
} from "@/app/types";

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
  | "onboarding"
  | "create adventurer"
  | "future";

export type Network =
  | "mainnet"
  | "katana"
  | "sepolia"
  | "localKatana"
  | undefined;

type State = {
  disconnected: boolean;
  setDisconnected: (value: boolean) => void;
  isWrongNetwork: boolean;
  setIsWrongNetwork: (value: boolean) => void;
  onboarded: boolean;
  handleOnboarded: () => void;
  handleOffboarded: () => void;
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
  inventorySelected: number | null;
  setInventorySelected: (value: number) => void;
  upgradeScreen: number;
  setUpgradeScreen: (value: number) => void;
  startOption: string | null;
  setStartOption: (value: string) => void;
  arcadeDialog: boolean;
  showArcadeDialog: (value: boolean) => void;
  arcadeIntro: boolean;
  showArcadeIntro: (value: boolean) => void;
  closedArcadeIntro: boolean;
  setClosedArcadeIntro: (value: boolean) => void;
  topUpDialog: boolean;
  showTopUpDialog: (value: boolean) => void;
  topUpAccount: string;
  setTopUpAccount: (value: string) => void;
  estimatingFee: boolean;
  setEstimatingFee: (value: boolean) => void;
  switchAdventurer: boolean;
  setSwitchAdventurer: (value: boolean) => void;
  specialBeastDefeated: boolean;
  setSpecialBeastDefeated: (value: boolean) => void;
  specialBeast: SpecialBeast | null;
  setSpecialBeast: (value: SpecialBeast | null) => void;
  isMintingLords: boolean;
  setIsMintingLords: (value: boolean) => void;
  isWithdrawing: boolean;
  setIsWithdrawing: (value: boolean) => void;
  averageBlockTime: number;
  setAverageBlockTime: (value: number) => void;
  adventurerEntropy: bigint;
  setAdventurerEntropy: (value: bigint) => void;
  entropyReady: boolean;
  setEntropyReady: (value: boolean) => void;
  loginScreen: boolean;
  setLoginScreen: (value: boolean) => void;
  network: Network;
  setNetwork: (value: Network) => void;
  onMainnet: boolean;
  onSepolia: boolean;
  onKatana: boolean;
  encounterTable: boolean;
  battleDialog: boolean;
  fleeDialog: boolean;
  showEncounterTable: (value: boolean) => void;
  showBattleDialog: (value: boolean) => void;
  showFleeDialog: (value: boolean) => void;
  vitBoostRemoved: number;
  setVitBoostRemoved: (value: number) => void;
  chaBoostRemoved: number;
  setChaBoostRemoved: (value: number) => void;
  showProfile: boolean;
  setShowProfile: (value: boolean) => void;
  username: string;
  setUsername: (value: string) => void;
  isController: boolean;
  setIsController: (value: boolean) => void;
  controllerAdmin: string;
  setControllerAdmin: (value: string) => void;
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
  handleOffboarded: () => {
    set({ onboarded: false });
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
  inventorySelected: null,
  setInventorySelected: (value) => set({ inventorySelected: value }),
  upgradeScreen: 1,
  setUpgradeScreen: (value) => set({ upgradeScreen: value }),
  startOption: "",
  setStartOption: (value) => set({ startOption: value }),
  arcadeDialog: false,
  showArcadeDialog: (value) => set({ arcadeDialog: value }),
  arcadeIntro: false,
  showArcadeIntro: (value) => set({ arcadeIntro: value }),
  closedArcadeIntro: false,
  setClosedArcadeIntro: (value) => set({ closedArcadeIntro: value }),
  topUpDialog: false,
  showTopUpDialog: (value) => set({ topUpDialog: value }),
  topUpAccount: "",
  setTopUpAccount: (value) => set({ topUpAccount: value }),
  estimatingFee: false,
  setEstimatingFee: (value) => set({ estimatingFee: value }),
  switchAdventurer: false,
  setSwitchAdventurer: (value) => set({ switchAdventurer: value }),
  specialBeastDefeated: false,
  setSpecialBeastDefeated: (value) => set({ specialBeastDefeated: value }),
  specialBeast: null,
  setSpecialBeast: (value) => set({ specialBeast: value }),
  isMintingLords: false,
  setIsMintingLords: (value) => set({ isMintingLords: value }),
  isWithdrawing: false,
  setIsWithdrawing: (value) => set({ isWithdrawing: value }),
  averageBlockTime: 0,
  setAverageBlockTime: (value) => set({ averageBlockTime: value }),
  adventurerEntropy: BigInt(0),
  setAdventurerEntropy: (value) => set({ adventurerEntropy: value }),
  entropyReady: false,
  setEntropyReady: (value) => set({ entropyReady: value }),
  loginScreen: false,
  setLoginScreen: (value) => set({ loginScreen: value }),
  network: undefined,
  setNetwork: (value) => {
    set({ network: value });
    set({ onMainnet: value === "mainnet" });
    set({ onSepolia: value === "sepolia" });
    set({ onKatana: value === "katana" || value === "localKatana" });
  },
  onMainnet: false,
  onSepolia: false,
  onKatana: false,
  encounterTable: false,
  battleDialog: false,
  fleeDialog: false,
  showEncounterTable: (value) => set({ encounterTable: value }),
  showBattleDialog: (value) => set({ battleDialog: value }),
  showFleeDialog: (value) => set({ fleeDialog: value }),
  vitBoostRemoved: 0,
  setVitBoostRemoved: (value) => set({ vitBoostRemoved: value }),
  chaBoostRemoved: 0,
  setChaBoostRemoved: (value) => set({ chaBoostRemoved: value }),
  showProfile: false,
  setShowProfile: (value) => set({ showProfile: value }),
  username: "",
  setUsername: (value) => set({ username: value }),
  isController: false,
  setIsController: (value) => set({ isController: value }),
  controllerAdmin: "",
  setControllerAdmin: (value) => set({ controllerAdmin: value }),
}));

export default useUIStore;
