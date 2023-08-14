import { useEffect, useState } from "react";
import { useWaitForTransaction } from "@starknet-react/core";
import { displayAddress, padAddress } from "../../lib/utils";
import { useQueriesStore } from "../../hooks/useQueryStore";
import useLoadingStore from "../../hooks/useLoadingStore";
import LootIconLoader from "../icons/Loader";
import useTransactionCartStore from "../../hooks/useTransactionCartStore";
import { useMediaQuery } from "react-responsive";
import { processNotifications } from "../notifications/NotificationHandler";
import useUIStore from "@/app/hooks/useUIStore";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { DiscoveryDisplay } from "../actions/DiscoveryDisplay";
import { NotificationBattleDisplay } from "../beast/BattleDisplay";
import { NullAdventurer } from "@/app/types";
import useCustomQuery from "@/app/hooks/useCustomQuery";
import {
  getBattleByTxHash,
  getDiscoveryByTxHash,
  getAdventurerById,
} from "@/app/hooks/graphql/queries";

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
  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);
  const isAlive = useAdventurerStore((state) => state.computed.isAlive);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const deathMessage = useLoadingStore((state) => state.deathMessage);
  const setDeathMessage = useLoadingStore((state) => state.setDeathMessage);
  const showDeathDialog = useUIStore((state) => state.showDeathDialog);
  const setScreen = useUIStore((state) => state.setScreen);
  const hasStatUpgrades = useAdventurerStore(
    (state) => state.computed.hasStatUpgrades
  );
  const {
    data: queryData,
    isDataUpdated,
    refetch,
    resetDataUpdated,
    resetData,
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
  const isLoadingQueryUpdated = isDataUpdated[loadingQuery!];

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  const setDeathNotification = (
    type: string,
    notificationData: any,
    battles: any,
    hasBeast: boolean
  ) => {
    const notifications = processNotifications(
      type,
      notificationData,
      battles,
      hasBeast,
      adventurer ?? NullAdventurer
    );
    // In the case of a chain of notifications we are only interested in the last
    setDeathMessage(notifications[notifications.length - 1].message);
    showDeathDialog(true);
  };

  useCustomQuery(
    "battlesByTxHashQuery",
    getBattleByTxHash,
    {
      txHash: padAddress(hash),
    },
    txAccepted,
    !hash
  );

  useCustomQuery(
    "discoveryByTxHashQuery",
    getDiscoveryByTxHash,
    {
      txHash: padAddress(hash),
    },
    txAccepted,
    !hash
  );

  console.log(txAccepted, hash, isLoadingQueryUpdated);

  useEffect(() => {
    const fetchData = async () => {
      console.log(txAccepted, hash, isLoadingQueryUpdated);
      if (!txAccepted || !hash || !isLoadingQueryUpdated) return;

      const handleAttackOrFlee = async () => {
        if (!queryData?.battlesByTxHashQuery) return;
        await refetch("battlesByTxHashQuery");
        // await refetch("adventurerByIdQuery");
        await refetch("battlesByBeastQuery");
        await refetch("battlesByAdventurerQuery");
        await refetch("latestMarketItemsQuery");
        console.log("in battle");
        const killedByBeast = queryData.battlesByTxHashQuery.battles.some(
          (battle) => battle.attacker == "Beast" && battle.adventurerHealth == 0
        );
        const killedByPenalty = queryData.battlesByTxHashQuery.battles.some(
          (battle) => !battle.attacker && battle.adventurerHealth == 0
        );
        if (killedByBeast || killedByPenalty) {
          setDeathNotification(
            type,
            queryData.battlesByTxHashQuery.battles,
            queryData.battlesByBeastQuery?.battles,
            true
          );
        }
        stopLoading(queryData.battlesByTxHashQuery.battles);
      };

      const handleExplore = async () => {
        if (!queryData?.discoveryByTxHashQuery) return;

        await refetch("discoveryByTxHashQuery");
        await refetch("discoveriesQuery");
        await refetch("latestDiscoveriesQuery");
        // await refetch("adventurerByIdQuery");
        await refetch("lastBeastBattleQuery");
        await refetch("lastBeastQuery");
        await refetch("beastQuery");
        await refetch("latestMarketItemsQuery");
        const killedByObstacle =
          queryData.discoveryByTxHashQuery.discoveries[0]?.discoveryType ==
            "Obstacle" &&
          queryData.discoveryByTxHashQuery.discoveries[0]?.adventurerHealth ==
            0;
        const killedByPenalty =
          !queryData.discoveryByTxHashQuery.discoveries[0]?.discoveryType &&
          queryData.discoveryByTxHashQuery.discoveries[0]?.adventurerHealth ==
            0;
        const killedByAmbush =
          queryData.discoveryByTxHashQuery.discoveries[0]?.ambushed &&
          queryData.discoveryByTxHashQuery.discoveries[0]?.adventurerHealth ==
            0;
        if (killedByObstacle || killedByPenalty || killedByAmbush) {
          setDeathNotification(
            type,
            queryData.discoveryByTxHashQuery.discoveries,
            queryData.battlesByBeastQuery?.battles,
            hasBeast
          );
        }
        stopLoading(queryData.discoveryByTxHashQuery.discoveries);
      };

      const handleUpgrade = async () => {
        // await refetch("adventurerByIdQuery");
        await refetch("latestMarketItemsQuery");
        stopLoading(notificationData);
        if (!hasStatUpgrades) {
          setScreen("play");
        }
      };

      const handleMulticall = async () => {
        console.log(loadingQuery, isLoadingQueryUpdated);
        // await refetch("adventurerByIdQuery");
        await refetch("itemsByAdventurerQuery");
        await refetch("battlesByBeastQuery");
        await refetch("latestMarketItemsQuery");
        const killedFromEquipping =
          (pendingMessage as string[]).includes("Equipping") && !isAlive;
        if (killedFromEquipping) {
          setDeathNotification(type, notificationData, [], true);
        }
        stopLoading(notificationData);
      };

      const handleCreate = async () => {
        console.log("in create");
        await refetch("adventurersByOwnerQuery");
        await refetch("adventurerByIdQuery");
        stopLoading(notificationData);
      };

      const handleDefault = async () => {
        stopLoading(notificationData);
      };

      const handleDataUpdate = () => {
        setTxAccepted(false);
        resetDataUpdated(loadingQuery!);
      };

      console.log(type);

      try {
        switch (type) {
          case "Attack":
            await handleAttackOrFlee();
            break;
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
          case "Create":
            await handleCreate();
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
  }, [isLoadingQueryUpdated]);

  useEffect(() => {
    if (
      queryData.adventurerByIdQuery &&
      queryData.adventurerByIdQuery.adventurers[0]?.id
    ) {
      console.log("updated");
      console.log(queryData.adventurerByIdQuery.adventurers[0]);
      setAdventurer(queryData.adventurerByIdQuery.adventurers[0]);
    }
  }, [isLoadingQueryUpdated]);

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
        <div className="flex flex-row absolute top-3 sm:top-0 sm:relative items-center gap-5 justify-between text-xs sm:text-base">
          {hash && (
            <div className="flex flex-row gap-2">
              {!isMobileDevice && "Hash:"}
              <a
                href={`https://testnet.starkscan.co/tx/${padAddress(hash)}`}
                target="_blank"
                className="animate-pulse"
              >
                {displayAddress(hash)}
              </a>
            </div>
          )}
          <div className="flex flex-row items-center w-40 sm:w-48 loading-ellipsis">
            <LootIconLoader
              className="self-center mr-3"
              size={isMobileDevice ? "w-4" : "w-5"}
            />
            {hash
              ? pendingArray
                ? (pendingMessage as string[])[messageIndex]
                : pendingMessage
              : "Confirming Tx"}
          </div>
          {data && hash && (
            <div>
              {!isMobileDevice && "Status:"} {data.status}
            </div>
          )}
        </div>
      ) : null}
    </>
  );
};
