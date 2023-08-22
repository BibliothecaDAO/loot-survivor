import { create } from "zustand";
import { isEqual } from "lodash";
import { Battle, Beast, Item, Adventurer, Discovery, Score } from "../types";

export type QueryKey =
  | "lastBattleQuery"
  | "lastBeastBattleQuery"
  | "battlesByAdventurerQuery"
  | "battlesByTxHashQuery"
  | "battlesByBeastQuery"
  | "lastBeastQuery"
  | "beastQuery"
  | "discoveriesQuery"
  | "latestDiscoveriesQuery"
  | "discoveryByTxHashQuery"
  | "adventurersByOwnerQuery"
  | "adventurerByIdQuery"
  | "leaderboardByIdQuery"
  | "adventurersByGoldQuery"
  | "adventurersByXPQuery"
  | "adventurersInListQuery"
  | "adventurersInListByXpQuery"
  | "itemsByAdventurerQuery"
  | "itemsByProfileQuery"
  | "topScoresQuery"
  | "latestMarketItemsQuery"
  | "adventurerToSlayQuery";

interface BattlesResult {
  battles: Battle[];
}

interface DiscoveriesResult {
  discoveries: Discovery[];
}

interface BeastsResult {
  beasts: Beast[];
}

interface AdventurersResult {
  adventurers: Adventurer[];
}

interface ItemsResult {
  items: Item[];
}

interface ScoresResult {
  scores: Score[];
}

interface InitialData {
  lastBattleQuery: BattlesResult | null;
  lastBeastBattleQuery: BattlesResult | null;
  battlesByAdventurerQuery: BattlesResult | null;
  battlesByTxHashQuery: BattlesResult | null;
  battlesByBeastQuery: BattlesResult | null;
  lastBeastQuery: DiscoveriesResult | null;
  beastQuery: BeastsResult | null;
  discoveriesQuery: DiscoveriesResult | null;
  latestDiscoveriesQuery: DiscoveriesResult | null;
  discoveryByTxHashQuery: DiscoveriesResult | null;
  adventurersByOwnerQuery: AdventurersResult | null;
  adventurerByIdQuery: AdventurersResult | null;
  leaderboardByIdQuery: AdventurersResult | null;
  adventurersByGoldQuery: AdventurersResult | null;
  adventurersByXPQuery: AdventurersResult | null;
  adventurersInListQuery: AdventurersResult | null;
  adventurersInListByXpQuery: AdventurersResult | null;
  itemsByAdventurerQuery: ItemsResult | null;
  itemsByProfileQuery: ItemsResult | null;
  topScoresQuery: ScoresResult | null;
  latestMarketItemsQuery: ItemsResult | null;
  adventurerToSlayQuery: AdventurersResult | null;
}

type QueriesState = {
  data: InitialData;
  setData: (queryKey: QueryKey, data: any) => void;
  isLoading: Record<QueryKey, boolean>;
  isDataUpdated: Record<QueryKey, boolean> & { global: boolean };
  refetchFunctions: Record<QueryKey, () => Promise<any>>;
  updateData: (
    queryKey: QueryKey,
    newData: any,
    loading: boolean,
    refetch: () => Promise<void>
  ) => void;
  refetch: (queryKey?: QueryKey) => Promise<void>;
  resetData: (queryKey?: QueryKey) => void;
  resetDataUpdated: (queryKey?: QueryKey) => void;
};

const initialData: InitialData = {
  lastBattleQuery: null,
  lastBeastBattleQuery: null,
  battlesByAdventurerQuery: null,
  battlesByTxHashQuery: null,
  battlesByBeastQuery: null,
  lastBeastQuery: null,
  beastQuery: null,
  discoveriesQuery: null,
  latestDiscoveriesQuery: null,
  discoveryByTxHashQuery: null,
  adventurersByOwnerQuery: null,
  adventurerByIdQuery: null,
  leaderboardByIdQuery: null,
  adventurersByGoldQuery: null,
  adventurersByXPQuery: null,
  adventurersInListQuery: null,
  adventurersInListByXpQuery: null,
  itemsByAdventurerQuery: null,
  itemsByProfileQuery: null,
  topScoresQuery: null,
  latestMarketItemsQuery: null,
  adventurerToSlayQuery: null,
};

const initialLoading: Record<QueryKey, boolean> = {
  lastBattleQuery: false,
  lastBeastBattleQuery: false,
  battlesByAdventurerQuery: false,
  battlesByTxHashQuery: false,
  battlesByBeastQuery: false,
  lastBeastQuery: false,
  beastQuery: false,
  discoveriesQuery: false,
  latestDiscoveriesQuery: false,
  discoveryByTxHashQuery: false,
  adventurersByOwnerQuery: false,
  adventurerByIdQuery: false,
  leaderboardByIdQuery: false,
  adventurersByGoldQuery: false,
  adventurersByXPQuery: false,
  adventurersInListQuery: false,
  adventurersInListByXpQuery: false,
  itemsByAdventurerQuery: false,
  itemsByProfileQuery: false,
  topScoresQuery: false,
  latestMarketItemsQuery: false,
  adventurerToSlayQuery: false,
};

const initialIsDataUpdated: Record<QueryKey, boolean> & { global: boolean } = {
  lastBattleQuery: false,
  lastBeastBattleQuery: false,
  battlesByAdventurerQuery: false,
  battlesByTxHashQuery: false,
  battlesByBeastQuery: false,
  lastBeastQuery: false,
  beastQuery: false,
  discoveriesQuery: false,
  latestDiscoveriesQuery: false,
  discoveryByTxHashQuery: false,
  adventurersByOwnerQuery: false,
  adventurerByIdQuery: false,
  leaderboardByIdQuery: false,
  adventurersByGoldQuery: false,
  adventurersByXPQuery: false,
  adventurersInListQuery: false,
  adventurersInListByXpQuery: false,
  itemsByAdventurerQuery: false,
  itemsByProfileQuery: false,
  topScoresQuery: false,
  latestMarketItemsQuery: false,
  adventurerToSlayQuery: false,
  global: false,
};

const initialRefetchFunctions: Record<QueryKey, () => Promise<any>> = {
  lastBattleQuery: async () => {},
  lastBeastBattleQuery: async () => {},
  battlesByAdventurerQuery: async () => {},
  battlesByTxHashQuery: async () => {},
  battlesByBeastQuery: async () => {},
  lastBeastQuery: async () => {},
  beastQuery: async () => {},
  discoveriesQuery: async () => {},
  latestDiscoveriesQuery: async () => {},
  discoveryByTxHashQuery: async () => {},
  adventurersByOwnerQuery: async () => {},
  adventurerByIdQuery: async () => {},
  leaderboardByIdQuery: async () => {},
  adventurersByGoldQuery: async () => {},
  adventurersByXPQuery: async () => {},
  adventurersInListQuery: async () => {},
  adventurersInListByXpQuery: async () => {},
  itemsByAdventurerQuery: async () => {},
  itemsByProfileQuery: async () => {},
  topScoresQuery: async () => {},
  latestMarketItemsQuery: async () => {},
  adventurerToSlayQuery: async () => {},
};

export const useQueriesStore = create<QueriesState>((set, get) => ({
  data: initialData,
  setData: (queryKey, newData) => {
    set((state) => ({
      data: { ...state.data, [queryKey]: newData },
      isDataUpdated: { ...state.isDataUpdated, [queryKey]: true },
    }));
    console.log(get().data, get().isDataUpdated);
  },
  isLoading: initialLoading,
  isDataUpdated: initialIsDataUpdated,
  refetchFunctions: initialRefetchFunctions,
  updateData: (queryKey, newData, loading) => {
    set((state) => {
      return {
        ...state,
        data: { ...state.data, [queryKey]: newData },
        isLoading: { ...state.isLoading, [queryKey]: loading },
      };
    });
  },
  resetData: (queryKey) => {
    if (queryKey) {
      set((state) => ({
        data: { ...state.data, [queryKey]: null },
      }));
    } else {
      set({ data: initialData });
    }
  },
  resetDataUpdated: (queryKey) => {
    if (queryKey) {
      set((state) => ({
        isDataUpdated: { ...state.isDataUpdated, [queryKey]: false },
      }));
    } else {
      set({ isDataUpdated: initialIsDataUpdated });
    }
  },
  refetch: async (queryKey) => {
    const { refetchFunctions } = get();
    if (queryKey) {
      const refetch = refetchFunctions[queryKey];

      if (refetch) {
        try {
          await refetch();
        } catch (error) {
          console.error(`Error refetching ${queryKey}:`, error);
          throw error;
        }
      } else {
        const warningMessage = `No refetch function found for query key: ${queryKey}`;
        console.warn(warningMessage);
        throw new Error(warningMessage); // This will throw the error to be caught in the component
      }
    } else {
      // If no queryKey is supplied, refetch all queries
      const allKeys = Object.keys(refetchFunctions);
      for (let key of allKeys) {
        const refetch = refetchFunctions[key as QueryKey];
        try {
          await refetch();
        } catch (error) {
          console.error(`Error refetching ${key}:`, error);
        }
      }
    }
  },
}));
