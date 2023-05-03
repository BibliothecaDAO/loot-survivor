import { create } from "zustand";
import { Adventurer, NullAdventurer } from "../types";
import { AdventurerClass } from "../lib/classes";

export interface AdventurerProps {
  adventurer: AdventurerClass | undefined;
  image: string | undefined;
}

type State = {
  adventurer?: AdventurerClass | undefined;
  setAdventurer: (value: Adventurer) => void;
  image?: string;
  setImage: (value: string) => void;
};

const useAdventurerStore = create<State>((set) => ({
  adventurer: new AdventurerClass(NullAdventurer),
  setAdventurer: (value) =>
    set((state) => ({
      ...state,
      adventurer: new AdventurerClass(value),
    })),
  image: undefined,
  setImage: (value) => set({ image: value }),
}));

export default useAdventurerStore;
