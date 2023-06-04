"use client";
import { useEffect, useState } from "react";
import { useWaitForTransaction, useAccount } from "@starknet-react/core";
import { displayAddress, padAddress } from "../lib/utils";
import { useQueriesStore } from "../hooks/useQueryStore";
import useLoadingStore from "../hooks/useLoadingStore";
import LootIconLoader from "./Loader";
import useAdventurerStore from "../hooks/useAdventurerStore";
import {
  getAdventurerById,
  getAdventurersInList,
  getAdventurersInListByXp,
  getBattleByTxHash,
  getBeasts,
  getLastDiscovery,
  getAdventurerByXP,
  getDiscoveries,
  getLatestDiscoveries,
  getLastBattleByAdventurer,
  getBattlesByAdventurer,
  getBattlesByBeast,
  getDiscoveryByTxHash,
  getAdventurersByOwner,
  getLatestMarketItems,
  getLatestMarketItemsNumber,
  getBeastById,
  getTopScores,
  getItemsByAdventurer,
  getUnclaimedItemsByAdventurer,
} from "../hooks/graphql/queries";
import useCustomQuery from "../hooks/useCustomQuery";
import useTransactionCartStore from "../hooks/useTransactionCartStore";

export interface TxActivityProps {
  hash: string | undefined;
}

export const TxActivity = () => {
  const notificationData = useLoadingStore((state) => state.notificationData);
  const loadingQuery = useLoadingStore((state) => state.loadingQuery);
  const stopLoading = useLoadingStore((state) => state.stopLoading);
  const loading = useLoadingStore((state) => state.loading);
  const hash = useLoadingStore((state) => state.hash);
  const pendingMessage = useLoadingStore((state) => state.pendingMessage);
  const type = useLoadingStore((state) => state.type);
  const loadingAdventurer = useLoadingStore((state) => state.adventurer);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const error = useTransactionCartStore((state) => state.error);
  const setError = useTransactionCartStore((state) => state.setError);
  const {
    data: queryData,
    isDataUpdated,
    refetch,
    resetDataUpdated,
  } = useQueriesStore();
  const [accepted, setAccepted] = useState(false);
  const { data } = useWaitForTransaction({
    hash,
    watch: true,
    onAcceptedOnL2: () => {
      setAccepted(true);
    },
    onRejected: () => {
      stopLoading("Rejected");
    },
  });
  const pendingArray = Array.isArray(pendingMessage);
  const [messageIndex, setMessageIndex] = useState(0);

  const { account } = useAccount();

  useCustomQuery(
    "adventurersByOwnerQuery",
    getAdventurersByOwner,
    {
      owner: padAddress(account?.address ?? ""),
    },
    undefined
  );

  const adventurers = queryData.adventurersByOwnerQuery
    ? queryData.adventurersByOwnerQuery.adventurers
    : [];

  useCustomQuery("beastsQuery", getBeasts, undefined, undefined);

  useCustomQuery("adventurerByIdQuery", getAdventurerById, {
    id: adventurer?.id ?? 0,
  });

  useCustomQuery(
    "battlesByTxHashQuery",
    getBattleByTxHash,
    {
      txHash: padAddress(hash),
    },
    undefined
  );

  useCustomQuery(
    "discoveryByTxHashQuery",
    getDiscoveryByTxHash,
    {
      txHash: padAddress(hash),
    },
    undefined
  );

  useCustomQuery("lastBattleQuery", getLastBattleByAdventurer, {
    adventurerId: adventurer?.id ?? 0,
  });

  useCustomQuery("battlesByBeastQuery", getBattlesByBeast, {
    adventurerId: adventurer?.id ?? 0,
    beastId: adventurer?.beastId
      ? adventurer?.beastId
      : queryData.lastBattleQuery?.battles[0]?.beastId,
  });

  useCustomQuery("beastByIdQuery", getBeastById, {
    id: adventurer?.beastId
      ? adventurer?.beastId
      : queryData.lastBattleQuery?.battles[0]?.beastId,
  });

  useCustomQuery(
    "latestMarketItemsNumberQuery",
    getLatestMarketItemsNumber,
    undefined,
    undefined
  );

  const latestMarketItemsNumber = queryData.latestMarketItemsNumberQuery
    ? queryData.latestMarketItemsNumberQuery.market[0]?.itemsNumber
    : [];

  useCustomQuery(
    "latestMarketItemsQuery",
    getLatestMarketItems,
    {
      itemsNumber: latestMarketItemsNumber,
    },
    undefined
  );

  useCustomQuery(
    "adventurersByXPQuery",
    getAdventurerByXP,
    undefined,
    undefined
  );

  useEffect(() => {
    // Check if loading, loadingQuery, and isDataUpdated are truthy
    if (accepted && hash && loadingQuery && isDataUpdated[loadingQuery]) {
      // Handle "Attack" or "Flee" types
      if (type === "Attack" || type === "Flee") {
        if (queryData?.battlesByTxHashQuery) {
          refetch("battlesByTxHashQuery");
          refetch("adventurerByIdQuery");
          refetch("battlesByBeastQuery");
          stopLoading({
            data: queryData.battlesByTxHashQuery.battles,
            beast: notificationData.beast,
          });
        }
        setAccepted(false);
        resetDataUpdated(loadingQuery);
      }

      // Handle "Explore" type
      else if (type === "Explore") {
        if (queryData?.discoveryByTxHashQuery) {
          refetch("discoveryByTxHashQuery");
          refetch("latestDiscoveriesQuery");
          refetch("adventurerByIdQuery");
          refetch("beastByIdQuery");
          stopLoading(queryData.discoveryByTxHashQuery.discoveries[0]);
          setAccepted(false);
          resetDataUpdated(loadingQuery);
        }
      } else if (type == "Upgrade") {
        stopLoading(notificationData);
        setAccepted(false);
        resetDataUpdated(loadingQuery);
      } else if (
        type == "Multicall" &&
        notificationData.some((noti: string) => noti.startsWith("You equipped"))
      ) {
        refetch("adventurerByIdQuery");
        refetch("battlesByBeastQuery");
        stopLoading(notificationData);
        setAccepted(false);
        resetDataUpdated(loadingQuery);
      }

      // Handle other types
      else {
        stopLoading(notificationData);
        setAccepted(false);
        resetDataUpdated(loadingQuery);
      }
    }
  }, [loadingQuery && isDataUpdated[loadingQuery], accepted, hash]);

  // stop loading when an error is caught
  useEffect(() => {
    if (error === true) {
      stopLoading(undefined);
      setError(false); // reset the error state
    }
  }, [error, setError, stopLoading]);

  useEffect(() => {
    if (pendingArray) {
      const interval = setInterval(() => {
        setMessageIndex((prevIndex) => (prevIndex + 1) % pendingMessage.length);
      }, 2000);
      return () => clearInterval(interval); // This is important, it will clear the interval when the component is unmounted.
    }
  }, [pendingMessage, messageIndex]);

  return (
    <>
      {loading ? (
        <div className="flex flex-row items-center gap-5">
          <div className="flex w-48 loading-ellipsis">
            <LootIconLoader className="self-center mr-3" />
            {hash
              ? pendingArray
                ? (pendingMessage as string[])[messageIndex]
                : pendingMessage
              : "Confirming Tx"}
          </div>
          {hash && (
            <div className="flex flex-row gap-2">
              Hash:{" "}
              <a
                href={`https://testnet.starkscan.co/tx/${padAddress(hash)}`}
                target="_blank"
                className="animate-pulse"
              >
                {displayAddress(hash)}
              </a>
            </div>
          )}
          {data && hash && <div>Status: {data.status}</div>}
        </div>
      ) : null}
    </>
  );
};
