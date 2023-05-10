"use client";
import { useAccount, useConnectors } from "@starknet-react/core";
import { useState, useEffect, useMemo } from "react";
import { Button } from "./components/Button";
import HorizontalKeyboardControl, {
  ButtonData,
} from "./components/HorizontalMenu";
import Actions from "./components/Actions";
import Marketplace from "./components/Marketplace";
import Adventurer from "./components/Adventurer";
import Beast from "./components/Beast";
import { displayAddress, padAddress } from "./lib/utils";
import Inventory from "./components/Inventory";
import TransactionHistory from "./components/TransactionHistory";
import TransactionCart from "./components/TransactionCart";
import Upgrade from "./components/Upgrade";
import Intro from "./components/Intro";
import {
  AddDevnetEthButton,
  MintEthButton,
} from "./components/DevnetConnectors";
import Leaderboard from "./components/Leaderboard";
import { TxActivity } from "./components/TxActivity";
import useLoadingStore from "./hooks/useLoadingStore";
import useAdventurerStore from "./hooks/useAdventurerStore";
import usePrevious from "use-previous";
import { useLazyQuery, useQuery } from "@apollo/client";
import {
  getAdventurerById,
  getBattleByTxHash,
  getLastDiscovery,
  getLatestDiscoveries,
  getLastBattleByAdventurer,
  getBattlesByBeast,
  getDiscoveryByTxHash,
  getAdventurersByOwner,
  getLatestMarketItems,
  getLatestMarketItemsNumber,
  getBeastById,
} from "./hooks/graphql/queries";
import useUIStore from "./hooks/useUIStore";
import useIndexerStore from "./hooks/useIndexerStore";
import useTransactionCartStore from "./hooks/useTransactionCartStore";
import SpriteAnimation from "./components/SpriteAnimation";
import { CSSTransition } from "react-transition-group";
import { NotificationDisplay } from "./components/NotificationDisplay";
import { useMusic, musicSelector } from "./hooks/useMusic";
import { testnet_addr } from "./lib/constants";
import { NullAdventurer } from "./types";
import useCustomQuery from "./hooks/useCustomQuery";
import { useQueriesStore } from "./hooks/useQueryStore";

export default function Home() {
  const { disconnect } = useConnectors();
  const { account } = useAccount();
  const [isMuted, setIsMuted] = useState(false);

  const hash = useLoadingStore((state) => state.hash);
  const loading = useLoadingStore((state) => state.loading);
  const stopLoading = useLoadingStore((state) => state.stopLoading);
  const loadingQuery = useLoadingStore((state) => state.loadingQuery);
  const type = useLoadingStore((state) => state.type);
  const notificationData = useLoadingStore((state) => state.notificationData);
  const showNotification = useLoadingStore((state) => state.showNotification);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const calls = useTransactionCartStore((state) => state.calls);
  const connected = useUIStore((state) => state.connected);
  const setConnected = useUIStore((state) => state.setConnected);
  const setIndexer = useIndexerStore((state) => state.setIndexer);
  const [showBattleScene, setShowBattleScene] = useState(true);
  const upgrade = adventurer?.upgrading;
  const status = adventurer?.status;

  const { data, isDataUpdated, refetch } = useQueriesStore();

  useCustomQuery("adventurersByOwnerQuery", getAdventurersByOwner, {
    owner: padAddress(account?.address ?? ""),
  });
  useCustomQuery("adventurerByIdQuery", getAdventurerById, {
    id: adventurer?.id ?? 0,
  });
  useCustomQuery("adventurersByGoldQuery", getAdventurerById);

  useCustomQuery("latestMarketItemsNumberQuery", getLatestMarketItemsNumber);

  const latestMarketItemsNumber = data.latestMarketItemsNumberQuery
    ? data.latestMarketItemsNumberQuery.market[0]?.itemsNumber
    : [];

  useCustomQuery("latestMarketItemsQuery", getLatestMarketItems, {
    itemsNumber: latestMarketItemsNumber,
  });

  useCustomQuery("battlesByTxHashQuery", getBattleByTxHash, {
    txHash: padAddress(hash),
  });

  useCustomQuery("latestDiscoveriesQuery", getLatestDiscoveries, {
    adventurerId: adventurer?.id,
  });

  useCustomQuery("discoveryByTxHashQuery", getDiscoveryByTxHash, {
    txHash: padAddress(hash),
  });

  useCustomQuery("lastBattleQuery", getLastBattleByAdventurer, {
    adventurerId: adventurer?.id,
  });

  useCustomQuery("battlesByBeastQuery", getBattlesByBeast, {
    adventurerId: adventurer?.id ?? 0,
    beastId: adventurer?.beastId ?? 0,
  });

  useCustomQuery("beastByIdQuery", getBeastById, {
    id: adventurer?.beastId
      ? adventurer?.beastId
      : data.lastBattleQuery?.battles[0]?.beastId,
  });

  const updatedAdventurer = data.adventurerByIdQuery
    ? data.adventurerByIdQuery.adventurers[0]
    : NullAdventurer;

  useEffect(() => {
    setAdventurer(updatedAdventurer);
  }, [updatedAdventurer]);

  const hasBeast = !!adventurer?.beastId;

  const playState = useMemo(() => ({
    isInBattle: hasBeast,
    isDead: false, // set this to true when player is dead
    isMuted: isMuted,
  }), [hasBeast, isMuted]);

  const { play, stop } = useMusic(playState, {
    volume: 0.5,
    loop: true,
  });

  const [menu, setMenu] = useState<ButtonData[]>([
    {
      id: 1,
      label: "Start",
      value: "start",
      disabled: false,
    },
  ]);

  const [selected, setSelected] = useState(menu[0].value);


  useEffect(() => {
    if (!adventurer || adventurer?.health == 0) {
      setSelected(menu[0].value);
    }
  }, [adventurer]);

  useEffect(() => {
    if (!account?.address) {
      setConnected(false);
    }
  }, [account]);

  console.log(account)

  const goerli_graphql = "https://survivor-indexer.bibliothecadao.xyz:8080/goerli-graphql";
  const devnet_graphql = "https://survivor-indexer.bibliothecadao.xyz:8080/devnet-graphql";

  useEffect(() => {
    setIndexer(
      (account as any)?.baseUrl == testnet_addr
        ? devnet_graphql
        : goerli_graphql
    );
  }, [account]);

  useEffect(() => {
    let newMenu = [
      {
        id: 1,
        label: "Start",
        value: "start",
        disabled: false,
      },
    ];

    if (adventurer && adventurer.health > 0) {
      newMenu = [
        ...newMenu,
        {
          id: 2,
          label: "Actions",
          value: "actions",
          disabled: hasBeast,
        },
        {
          id: 3,
          label: "Market",
          value: "market",
          disabled: hasBeast,
        },
        {
          id: 4,
          label: "Inventory",
          value: "inventory",
          disabled: false,
        },
        {
          id: 5,
          label: "Beast",
          value: "beast",
          disabled: false,
        },
        {
          id: 6,
          label: "Leaderboard",
          value: "leaderboard",
          disabled: hasBeast,
        },
      ];
    }

    setMenu(newMenu);
  }, [adventurer, account]);

  // const showNotification = true;
  // const type = "Explore";
  // const notificationData = {
  //   adventurerId: 7,
  //   attackLocation: "Foot",
  //   discoveryTime: "2023-05-05T14:41:37",
  //   discoveryType: "Obstacle",
  //   entityId: null,
  //   outputAmount: 9,
  //   subDiscoveryType: "Dark Mist",
  //   txHash: "0x02526e0eef880bfb5efaf3b3b64f4307bc09b8b30ad5f5e323",
  // };
  const battleNotifData = {};

  return (
    <main
      className={`min-h-screen container mx-auto flex flex-col p-10 overflow-hidden`}
    >
      {connected ? (
        <>
          <div className="flex justify-between w-full ">
            <h1 className="glitch">Loot Survivor</h1>
            <div className="flex flex-row self-end gap-2">
              <TxActivity />
              <Button onClick={() => setIsMuted(!isMuted)}>
                {isMuted ? "Unmute" : "Mute"}
              </Button>
              {account && calls.length > 0 && <TransactionCart />}
              {account && <TransactionHistory />}
              {(account as any)?.baseUrl == testnet_addr && (
                <AddDevnetEthButton />
              )}
              {(account as any)?.baseUrl == testnet_addr && <MintEthButton />}
              {account && (
                <Button onClick={() => disconnect()}>
                  {displayAddress(account.address)}
                </Button>
              )}
            </div>
          </div>
          <div className="w-full h-6 my-2 bg-terminal-green" />
          <CSSTransition
            in={showNotification}
            timeout={500}
            classNames="notification"
            unmountOnExit
          >
            <div className="fixed top-0 left-0 w-1/4 mt-20 ml-20 border rounded-lg border-terminal-green bg-terminal-black">
              <NotificationDisplay
                type={type}
                notificationData={notificationData}
              />
            </div>
          </CSSTransition>

          {account ? (
            <div className="flex-grow w-full">
              {!upgrade ? (
                <>
                  <div className="gap-10 pb-2">
                    <HorizontalKeyboardControl
                      buttonsData={menu}
                      onButtonClick={(value) => {
                        setSelected(value);
                      }}
                    />
                  </div>

                  {selected === "start" && <Adventurer />}
                  {selected === "actions" && <Actions />}
                  {selected === "market" && <Marketplace />}
                  {selected === "inventory" && <Inventory />}
                  {selected === "beast" && <Beast />}
                  {selected === "leaderboard" && <Leaderboard />}
                </>
              ) : (
                <Upgrade />
              )}
            </div>
          ) : null}
        </>
      ) : (
        <Intro />
      )}
    </main>
  );
}
