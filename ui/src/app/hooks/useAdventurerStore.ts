import { create } from "zustand";
import { Adventurer, NullAdventurer } from "@/app/types";
import { AdventurerClass } from "@/app/lib/classes";

export interface AdventurerProps {
  adventurer: AdventurerClass | undefined;
  image: string | undefined;
}

type State = {
  adventurer?: AdventurerClass | undefined;
  setAdventurer: (value: Adventurer) => void;
  image?: string;
  setImage: (value: string) => void;
  computed: {
    hasBeast: boolean;
    hasStatUpgrades: boolean;
    isAlive: boolean;
    hasNoXp: boolean;
    currentLevel: number;
  };
};

const useAdventurerStore = create<State>((set, get) => ({
  adventurer: new AdventurerClass(NullAdventurer),
  setAdventurer: (value) =>
    set((state) => ({
      ...state,
      adventurer: new AdventurerClass(value),
    })),
  image: undefined,
  setImage: (value) => set({ image: value }),
  computed: {
    get hasBeast() {
      return (get().adventurer?.beastHealth ?? 0) > 0;
    },
    get hasStatUpgrades() {
      return (get().adventurer?.statUpgrades ?? 0) > 0;
    },
    get isAlive() {
      return (get().adventurer?.health ?? 0) > 0;
    },
    get hasNoXp() {
      return (get().adventurer?.xp ?? 0) === 0;
    },
    get currentLevel() {
      return get().adventurer?.level ?? 0;
    },
  },
}));

export default useAdventurerStore;
