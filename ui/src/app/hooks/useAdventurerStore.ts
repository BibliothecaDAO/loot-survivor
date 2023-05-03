import { create } from "zustand";
import { NullAdventurer } from "../types";
import { AdventurerClass } from "../lib/classes";

export interface AdventurerProps {
  adventurer: AdventurerClass | undefined;
  image: string | undefined;
}

type State = {
  adventurer?: AdventurerClass | undefined;
  setAdventurer: (value: AdventurerProps) => void;
  image?: string;
  setImage: (value: string) => void;
};

const useAdventurerStore = create<State>((set) => ({
  adventurer: new AdventurerClass(NullAdventurer),
  setAdventurer: (value) => set(value),
  image: undefined,
  setImage: (value) => set({ image: value }),
}));

export default useAdventurerStore;
