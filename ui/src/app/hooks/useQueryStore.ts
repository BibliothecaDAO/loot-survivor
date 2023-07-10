import { create } from "zustand";
import { isEqual } from "lodash";
import { Battle, Item, Adventurer, Discovery, Score } from "../types";

export type QueryKey =
  | "lastBattleQuery"
  | "lastBeastBattleQuery"
  | "battlesByAdventurerQuery"
  | "battlesByTxHashQuery"
  | "battlesByBeastQuery"
  | "lastBeastQuery"
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
  isLoading: Record<QueryKey, boolean>;
  isDataUpdated: Record<QueryKey, boolean> & { global: boolean };
  refetchFunctions: Record<QueryKey, () => Promise<any>>;
  updateData: (
    queryKey: QueryKey,
    newData: any,
    loading: boolean,
    refetch: () => Promise<void>
  ) => void;
  refetch: (queryKey: QueryKey) => Promise<void>;
  resetDataUpdated: (queryKey?: QueryKey) => void;
};

const initialData: InitialData = {
  lastBattleQuery: null,
  lastBeastBattleQuery: null,
  battlesByAdventurerQuery: null,
  battlesByTxHashQuery: null,
  battlesByBeastQuery: null,
  lastBeastQuery: null,
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
  isLoading: initialLoading,
  isDataUpdated: initialIsDataUpdated,
  refetchFunctions: initialRefetchFunctions,
  updateData: (queryKey, newData, loading, refetch) => {
    set((state) => {
      const oldData = state.data[queryKey];
      const queryKeysToIgnore = [
        "battlesByTxHashQuery",
        "discoveryByTxHashQuery",
      ];
      const hasEmptyArray =
        newData && typeof newData === "object"
          ? Object.values(newData).some(
              (arr) => Array.isArray(arr) && arr.length === 0
            )
          : false;
      const ignoreDataChange =
        queryKeysToIgnore.includes(queryKey) && hasEmptyArray;
      const isDataChanged =
        !ignoreDataChange &&
        (oldData !== null ||
          (newData && Object.values(newData).some((arr: any) => arr.length))) &&
        !isEqual(oldData, newData);
      if (isDataChanged && newData !== undefined) {
        return {
          ...state,
          data: { ...state.data, [queryKey]: newData },
          isLoading: { ...state.isLoading, [queryKey]: loading },
          isDataUpdated: {
            ...state.isDataUpdated,
            [queryKey]: true,
            global: true,
          },
          refetchFunctions: { ...state.refetchFunctions, [queryKey]: refetch },
        };
      }
      return state;
    });
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
  refetch: async (queryKey: QueryKey) => {
    const { refetchFunctions } = get();
    const refetch = refetchFunctions[queryKey];

    if (refetch) {
      try {
        await refetch();
      } catch (error) {
        console.error(`Error refetching ${queryKey}:`, error);
      }
    } else {
      console.warn(`No refetch function found for query key: ${queryKey}`);
    }
  },
}));
