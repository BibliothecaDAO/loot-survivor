import { create } from "zustand";
import { Battle, Beast, Item, Adventurer, Discovery, Score } from "@/app/types";
import { GameData } from "@/app/lib/data/GameData";

export type QueryKey =
  | "lastBattleQuery"
  | "lastBeastBattleQuery"
  | "battlesByAdventurerQuery"
  | "battlesByTxHashQuery"
  | "battlesByBeastQuery"
  | "lastBeastQuery"
  | "beastQuery"
  | "killedBeastsQuery"
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
  | "adventurerToSlayQuery"
  | "adventurerCountsQuery"
  | "discoveriesAndBattlesByAdventurerQuery"
  | "discoveryBattleCountsQuery"
  | "adventurersByOwnerCountQuery"
  | "aliveAdventurersByOwnerCountQuery"
  | "adventurerRankQuery";

export interface BattlesResult {
  [key: string]: Battle[];
  battles: Battle[];
}

export interface DiscoveriesResult {
  [key: string]: Battle[];
  discoveries: Discovery[];
}

export interface BeastsResult {
  [key: string]: Battle[];
  beasts: Beast[];
}

export interface AdventurersResult {
  [key: string]: Battle[];
  adventurers: Adventurer[];
}

export interface ItemsResult {
  [key: string]: Battle[];
  items: Item[];
}

export interface ScoresResult {
  [key: string]: Battle[];
  scores: Score[];
}

export interface AdventurerRankResult {
  adventurerRank: {
    rank: number;
  };
}

export interface QueryData {
  lastBattleQuery: BattlesResult | null;
  lastBeastBattleQuery: BattlesResult | null;
  battlesByAdventurerQuery: BattlesResult | null;
  battlesByTxHashQuery: BattlesResult | null;
  battlesByBeastQuery: BattlesResult | null;
  lastBeastQuery: DiscoveriesResult | null;
  beastQuery: BeastsResult | null;
  killedBeastsQuery: BeastsResult | null;
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
  adventurerCountsQuery: AdventurersResult | null;
  discoveriesAndBattlesByAdventurerQuery: DiscoveriesResult | null;
  discoveryBattleCountsQuery: DiscoveriesResult | null;
  adventurersByOwnerCountQuery: AdventurersResult | null;
  aliveAdventurersByOwnerCountQuery: AdventurersResult | null;
  adventurerRankQuery: AdventurersResult | null;
}

type QueriesState = {
  data: QueryData;
  setData: (
    queryKey: QueryKey,
    data: any,
    attribute?: string,
    index?: number
  ) => void;
  setRefetch: (queryKey: QueryKey, refetch: () => Promise<any>) => void;
  isLoading: Record<QueryKey, boolean> & { global: boolean };
  setIsLoading: (queryKey?: QueryKey) => void;
  setNotLoading: (queryKey?: QueryKey) => void;
  refetchFunctions: Record<QueryKey, (variables?: any) => Promise<any>>;
  refetch: (queryKey?: QueryKey, variables?: any) => Promise<any>;
  resetData: (queryKey?: QueryKey) => void;
};

const initialData: QueryData = {
  lastBattleQuery: null,
  lastBeastBattleQuery: null,
  battlesByAdventurerQuery: null,
  battlesByTxHashQuery: null,
  battlesByBeastQuery: null,
  lastBeastQuery: null,
  beastQuery: null,
  killedBeastsQuery: null,
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
  adventurerCountsQuery: null,
  discoveriesAndBattlesByAdventurerQuery: null,
  discoveryBattleCountsQuery: null,
  adventurersByOwnerCountQuery: null,
  aliveAdventurersByOwnerCountQuery: null,
  adventurerRankQuery: null,
};

const initialLoading: Record<QueryKey, boolean> & { global: boolean } = {
  lastBattleQuery: false,
  lastBeastBattleQuery: false,
  battlesByAdventurerQuery: false,
  battlesByTxHashQuery: false,
  battlesByBeastQuery: false,
  lastBeastQuery: false,
  beastQuery: false,
  killedBeastsQuery: false,
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
  adventurerCountsQuery: false,
  discoveriesAndBattlesByAdventurerQuery: false,
  discoveryBattleCountsQuery: false,
  adventurersByOwnerCountQuery: false,
  aliveAdventurersByOwnerCountQuery: false,
  adventurerRankQuery: false,
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
  killedBeastsQuery: async () => {},
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
  adventurerCountsQuery: async () => {},
  discoveriesAndBattlesByAdventurerQuery: async () => {},
  discoveryBattleCountsQuery: async () => {},
  adventurersByOwnerCountQuery: async () => {},
  aliveAdventurersByOwnerCountQuery: async () => {},
  adventurerRankQuery: async () => {},
};

export const useQueriesStore = create<QueriesState>((set, get) => ({
  data: initialData,
  setData: (queryKey, newData, attribute, index) => {
    const gameData = new GameData();
    set((state) => {
      if (typeof attribute === "string" && typeof index === "number") {
        // This assumes the data structure always contains an array, like battles, discoveries, etc.
        const existingData = state.data[queryKey];
        const internalKey = gameData.QUERY_KEYS[queryKey];

        if (!internalKey) {
          console.error("Internal key mapping not found for:", queryKey);
          return state;
        }

        if (!existingData) {
          console.error("Existing data not found for:", queryKey);
          return state;
        }

        const targetArray = [...existingData[internalKey]];

        if (targetArray[index]) {
          targetArray[index] = { ...targetArray[index], [attribute]: newData };
        }
        return {
          data: {
            ...state.data,
            [queryKey]: {
              [internalKey]: targetArray,
            },
          },
        };
      } else {
        return {
          data: { ...state.data, [queryKey]: newData },
        };
      }
    });
  },
  setRefetch: (queryKey, refetch) => {
    set((state) => {
      return {
        refetchFunctions: { ...state.refetchFunctions, [queryKey]: refetch },
      };
    });
  },
  isLoading: initialLoading,
  setIsLoading: (queryKey) => {
    if (queryKey) {
      set((state) => ({
        isLoading: { ...state.isLoading, [queryKey]: true },
      }));
    } else {
      set((state) => ({
        isLoading: { ...state.isLoading, global: true },
      }));
    }
  },
  setNotLoading: (queryKey) => {
    if (queryKey) {
      set((state) => ({
        isLoading: { ...state.isLoading, [queryKey]: false },
      }));
    } else {
      set((state) => ({
        isLoading: { ...state.isLoading, global: false },
      }));
    }
  },
  refetchFunctions: initialRefetchFunctions,
  resetData: (queryKey) => {
    if (queryKey) {
      set((state) => ({
        data: { ...state.data, [queryKey]: null },
      }));
    } else {
      set({ data: initialData });
    }
  },
  refetch: async (queryKey, variables) => {
    const { refetchFunctions } = get();
    if (queryKey) {
      const refetch = refetchFunctions[queryKey];

      if (refetch) {
        try {
          const newData = await refetch(variables);
          return newData;
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
      const newDataObject: Record<QueryKey, any> = {
        lastBattleQuery: null,
        lastBeastBattleQuery: null,
        battlesByAdventurerQuery: null,
        battlesByTxHashQuery: null,
        battlesByBeastQuery: null,
        lastBeastQuery: null,
        beastQuery: null,
        killedBeastsQuery: null,
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
        adventurerCountsQuery: null,
        discoveriesAndBattlesByAdventurerQuery: null,
        discoveryBattleCountsQuery: null,
        adventurersByOwnerCountQuery: null,
        aliveAdventurersByOwnerCountQuery: null,
        adventurerRankQuery: null,
      };
      for (let key of allKeys) {
        const refetch = refetchFunctions[key as QueryKey];
        try {
          const { data: newData } = await refetch();
          newDataObject[key as QueryKey] = newData;
        } catch (error) {
          console.error(`Error refetching ${key}:`, error);
        }
      }
      return newDataObject;
    }
  },
}));
