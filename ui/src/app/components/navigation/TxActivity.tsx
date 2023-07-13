import { useEffect, useState } from "react";
import { useWaitForTransaction, useAccount } from "@starknet-react/core";
import { displayAddress, padAddress } from "../../lib/utils";
import { useQueriesStore } from "../../hooks/useQueryStore";
import useLoadingStore from "../../hooks/useLoadingStore";
import LootIconLoader from "../icons/Loader";
import useTransactionCartStore from "../../hooks/useTransactionCartStore";
import useUIStore from "@/app/hooks/useUIStore";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";

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
  const txAccepted = useLoadingStore((state) => state.txAccepted);
  const setTxAccepted = useLoadingStore((state) => state.setTxAccepted);
  const type = useLoadingStore((state) => state.type);
  const error = useTransactionCartStore((state) => state.error);
  const setError = useTransactionCartStore((state) => state.setError);
  const setScreen = useUIStore((state) => state.setScreen);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const {
    data: queryData,
    isDataUpdated,
    refetch,
    resetDataUpdated,
  } = useQueriesStore();
  const { data } = useWaitForTransaction({
    hash,
    watch: true,
    onAcceptedOnL2: () => {
      setTxAccepted(true);
    },
    onRejected: () => {
      stopLoading("Rejected");
    },
  });
  const pendingArray = Array.isArray(pendingMessage);
  const [messageIndex, setMessageIndex] = useState(0);
  const isLoadingQueryUpdated = loadingQuery && isDataUpdated[loadingQuery];

  console.log(isLoadingQueryUpdated);
  console.log(queryData?.adventurerByIdQuery);

  useEffect(() => {
    const fetchData = async () => {
      if (!txAccepted || !hash || !isLoadingQueryUpdated) return;
  
      const handleAttackOrFlee = async () => {
        if (!queryData?.battlesByTxHashQuery) return;
  
        await refetch("battlesByTxHashQuery");
        await refetch("adventurerByIdQuery");
        await refetch("battlesByBeastQuery");
        stopLoading({
          data: queryData.battlesByTxHashQuery.battles,
          beast: notificationData.beast,
        });
      };
  
      const handleExplore = async () => {
        if (!queryData?.discoveryByTxHashQuery) return;
  
        await refetch("discoveryByTxHashQuery");
        await refetch("latestDiscoveriesQuery");
        await refetch("adventurerByIdQuery");
        await refetch("lastBeastBattleQuery");
        stopLoading(queryData.discoveryByTxHashQuery.discoveries[0]);
      };
  
      const handleUpgrade = async () => {
        stopLoading(notificationData);
      };
  
      const handleMulticall = async () => {
        if (!notificationData.some((noti: string) => noti.startsWith("You equipped"))) return;
  
        await refetch("adventurerByIdQuery");
        await refetch("battlesByBeastQuery");
        stopLoading(notificationData);
      };
  
      const handleDefault = async () => {
        stopLoading(notificationData);
      };
  
      const handleDataUpdate = () => {
        setTxAccepted(false);
        resetDataUpdated(loadingQuery);
        if ((adventurer?.statUpgrades ?? 0) > 0) {
          setScreen("upgrade");
        }
      };
  
      try {
        switch (type) {
          case "Attack":
          case "Flee":
            await handleAttackOrFlee();
            break;
          case "Explore":
            await handleExplore();
            break;
          case "Upgrade":
            await handleUpgrade();
            break;
          case "Multicall":
            await handleMulticall();
            break;
          default:
            await handleDefault();
            break;
        }
      } catch (error) {
        console.error("An error occurred during fetching:", error);
        // handle error (e.g., update state to show error message)
      }
  
      handleDataUpdate();
    };
  
    fetchData();
  }, [
    isLoadingQueryUpdated,
    txAccepted,
    hash,
    loadingQuery,
    notificationData,
    queryData.battlesByTxHashQuery,
    queryData.discoveryByTxHashQuery,
    refetch,
    resetDataUpdated,
    setTxAccepted,
    stopLoading,
    type,
  ]);

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
  }, [pendingMessage, messageIndex, pendingArray]);

  return (
    <>
      {loading ? (
        <div className="flex flex-row absolute top-5 sm:top-0 sm:relative items-center gap-5 justify-between text-xs sm:text-base">
          <div className="flex flex-row items-center w-32 sm:w-48 loading-ellipsis">
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
