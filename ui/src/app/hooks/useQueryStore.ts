import { create } from "zustand";
import { isEqual } from "lodash";

export type QueryKey =
  | "beastsQuery"
  | "lastBattleQuery"
  | "battlesByAdventurerQuery"
  | "battlesByBeastQuery"
  | "battlesByTxHashQuery"
  | "beastByIdQuery"
  | "discoveriesQuery"
  | "latestDiscoveriesQuery"
  | "discoveryByTxHashQuery"
  | "adventurersByOwnerQuery"
  | "adventurerByIdQuery"
  | "leaderboardByIdQuery"
  | "adventurersByGoldQuery"
  | "adventurersByXPQuery"
  | "unclaimedItemsByAdventurerQuery"
  | "latestMarketItemsNumberQuery"
  | "latestMarketItemsQuery"
  | "adventurersInListQuery"
  | "adventurersInListByXpQuery"
  | "itemsByAdventurerQuery"
  | "itemsByProfileQuery"
  | "topScoresQuery";

type QueriesState = {
  data: Record<QueryKey, any>;
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

const initialData: Record<QueryKey, any> = {
  beastsQuery: null,
  lastBattleQuery: null,
  battlesByAdventurerQuery: null,
  battlesByBeastQuery: null,
  battlesByTxHashQuery: null,
  beastByIdQuery: null,
  discoveriesQuery: null,
  latestDiscoveriesQuery: null,
  discoveryByTxHashQuery: null,
  adventurersByOwnerQuery: null,
  adventurerByIdQuery: null,
  leaderboardByIdQuery: null,
  adventurersByGoldQuery: null,
  adventurersByXPQuery: null,
  unclaimedItemsByAdventurerQuery: null,
  latestMarketItemsNumberQuery: null,
  latestMarketItemsQuery: null,
  adventurersInListQuery: null,
  adventurersInListByXpQuery: null,
  itemsByAdventurerQuery: null,
  itemsByProfileQuery: null,
  topScoresQuery: null,
};

const initialLoading: Record<QueryKey, boolean> = {
  beastsQuery: false,
  lastBattleQuery: false,
  battlesByAdventurerQuery: false,
  battlesByBeastQuery: false,
  battlesByTxHashQuery: false,
  beastByIdQuery: false,
  discoveriesQuery: false,
  latestDiscoveriesQuery: false,
  discoveryByTxHashQuery: false,
  adventurersByOwnerQuery: false,
  adventurerByIdQuery: false,
  leaderboardByIdQuery: false,
  adventurersByGoldQuery: false,
  adventurersByXPQuery: false,
  unclaimedItemsByAdventurerQuery: false,
  latestMarketItemsNumberQuery: false,
  latestMarketItemsQuery: false,
  adventurersInListQuery: false,
  adventurersInListByXpQuery: false,
  itemsByAdventurerQuery: false,
  itemsByProfileQuery: false,
  topScoresQuery: false,
};

const initialIsDataUpdated: Record<QueryKey, boolean> & { global: boolean } = {
  beastsQuery: false,
  lastBattleQuery: false,
  battlesByAdventurerQuery: false,
  battlesByBeastQuery: false,
  battlesByTxHashQuery: false,
  beastByIdQuery: false,
  discoveriesQuery: false,
  latestDiscoveriesQuery: false,
  discoveryByTxHashQuery: false,
  adventurersByOwnerQuery: false,
  adventurerByIdQuery: false,
  leaderboardByIdQuery: false,
  adventurersByGoldQuery: false,
  adventurersByXPQuery: false,
  unclaimedItemsByAdventurerQuery: false,
  latestMarketItemsNumberQuery: false,
  latestMarketItemsQuery: false,
  adventurersInListQuery: false,
  adventurersInListByXpQuery: false,
  itemsByAdventurerQuery: false,
  itemsByProfileQuery: false,
  topScoresQuery: false,
  global: false,
};

const initialRefetchFunctions: Record<QueryKey, () => Promise<any>> = {
  beastsQuery: async () => {},
  lastBattleQuery: async () => {},
  battlesByAdventurerQuery: async () => {},
  battlesByBeastQuery: async () => {},
  battlesByTxHashQuery: async () => {},
  beastByIdQuery: async () => {},
  discoveriesQuery: async () => {},
  latestDiscoveriesQuery: async () => {},
  discoveryByTxHashQuery: async () => {},
  adventurersByOwnerQuery: async () => {},
  adventurerByIdQuery: async () => {},
  leaderboardByIdQuery: async () => {},
  adventurersByGoldQuery: async () => {},
  adventurersByXPQuery: async () => {},
  unclaimedItemsByAdventurerQuery: async () => {},
  latestMarketItemsNumberQuery: async () => {},
  latestMarketItemsQuery: async () => {},
  adventurersInListQuery: async () => {},
  adventurersInListByXpQuery: async () => {},
  itemsByAdventurerQuery: async () => {},
  itemsByProfileQuery: async () => {},
  topScoresQuery: async () => {},
};

export const useQueriesStore = create<QueriesState>((set, get) => ({
  data: initialData,
  isLoading: initialLoading,
  isDataUpdated: initialIsDataUpdated,
  refetchFunctions: initialRefetchFunctions,
  updateData: (queryKey, newData, loading, refetch) => {
    set((state) => {
      const oldData = state.data[queryKey];
      const isDataChanged =
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
