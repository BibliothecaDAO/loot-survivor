import { create } from "zustand";
import { Adventurer } from "../types";

export interface AdventurerProps {
  adventurer: Adventurer | undefined;
  image: string | undefined;
}

type State = {
  adventurer?: AdventurerProps;
  setAdventurer: (value: AdventurerProps) => void;
};

const useAdventurerStore = create<State>((set) => ({
  adventurer: undefined,
  setAdventurer: (value) => set({ adventurer: value }),
}));

export default useAdventurerStore;
