"use client";
import { useAccount, useConnectors } from "@starknet-react/core";
import { useState, useEffect } from "react";
import { Button } from "./components/Button";
import HorizontalKeyboardControl from "./components/HorizontalMenu";
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
import { Menu, NullAdventurer } from "./types";
import useCustomQuery from "./hooks/useCustomQuery";
import { useQueriesStore } from "./hooks/useQueryStore";

export default function Home() {
  const { disconnect } = useConnectors();
  const { account } = useAccount();
  const [isMuted, setIsMuted] = useState(false);

  const hash = useLoadingStore((state) => state.hash);
  const type = useLoadingStore((state) => state.type);
  const notificationData = useLoadingStore((state) => state.notificationData);
  const showNotification = useLoadingStore((state) => state.showNotification);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const calls = useTransactionCartStore((state) => state.calls);
  const connected = useUIStore((state) => state.connected);
  const setConnected = useUIStore((state) => state.setConnected);
  const onboarded = useUIStore((state) => state.onboarded);
  const screen = useUIStore((state) => state.screen);
  const setScreen = useUIStore((state) => state.setScreen);
  const handleOnboarded = useUIStore((state) => state.handleOnboarded);
  const setIndexer = useIndexerStore((state) => state.setIndexer);

  const upgrade = adventurer?.upgrading;

  const { data } = useQueriesStore();

  useCustomQuery("adventurersByOwnerQuery", getAdventurersByOwner, {
    owner: padAddress(account?.address ?? ""),
  });

  const adventurers = data.adventurersByGoldQuery
    ? data.adventurersByOwnerQuery.adventurers
    : [];

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

  const { play, stop } = useMusic(musicSelector.backgroundMusic, {
    volume: 0.5,
    loop: true,
    isMuted: isMuted,
  });

  useEffect(() => {
    // play();

    return () => {
      stop();
    };
  }, [play, stop]);

  const [menu, setMenu] = useState<Menu[]>([
    {
      id: 1,
      label: "Start",
      screen: "start",
    },
  ]);

  useEffect(() => {
    if (!adventurer || adventurer?.health == 0) {
      setScreen(menu[0].screen);
    }
  }, [adventurer]);

  useEffect(() => {
    if (!account?.address) {
      setConnected(false);
    }
  }, [account]);

  useEffect(() => {
    setIndexer(
      (account as any)?.baseUrl == testnet_addr ||
        (account as any)?.provider?.baseUrl == "https://alpha4.starknet.io"
        ? "https://survivor-indexer.bibliothecadao.xyz:8080/devnet-graphql"
        : "https://survivor-indexer.bibliothecadao.xyz:8080/goerli-graphql"
    );
  }, [account]);

  useEffect(() => {
    if (onboarded) {
      let newMenu: Menu[] = [
        {
          id: 1,
          label: "Start",
          screen: "start",
        },
      ];

      if (adventurer && adventurer.health > 0) {
        newMenu = [
          ...newMenu,
          {
            id: 2,
            label: "Actions",
            screen: "actions",
          },
          {
            id: 3,
            label: "Market",
            screen: "market",
          },
          {
            id: 4,
            label: "Inventory",
            screen: "inventory",
          },
          {
            id: 5,
            label: "Beast",
            screen: "beast",
          },
          {
            id: 6,
            label: "Leaderboard",
            screen: "leaderboard",
          },
        ];
      }
      setMenu(newMenu);
    }
  }, [adventurer, account, onboarded]);

  useEffect(() => {
    if (adventurers.length == 0) {
      setMenu([
        {
          id: 1,
          label: "Start",
          screen: "start",
        },
      ]);
      setScreen(menu[0].screen);
    } else if (
      adventurers.length == 1 &&
      adventurer?.xp == 0 &&
      !adventurer.beastId
    ) {
      setMenu([
        {
          id: 1,
          label: "Actions",
          screen: "actions",
        },
      ]);
      setScreen(menu[0].screen);
    } else if (
      adventurers.length == 1 &&
      adventurer?.xp == 0 &&
      adventurer.beastId
    ) {
      setMenu([
        {
          id: 1,
          label: "Beast",
          screen: "beast",
        },
      ]);
      setScreen(menu[0].screen);
    } else {
      handleOnboarded();
    }
  }, [onboarded, adventurer]);

  return (
    <main className={`min-h-screen container mx-auto flex flex-col p-10`}>
      {connected ? (
        <>
          <div className="flex justify-between w-full ">
            <h1 className="glitch">M.O.R.T.A.L</h1>
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
            <div className="fixed top-0 left-0 mt-32 ml-20 w-1/4 border rounded-lg border-terminal-green bg-terminal-black">
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
                        setScreen(value);
                      }}
                    />
                  </div>

                  {screen === "start" && <Adventurer />}
                  {screen === "actions" && <Actions />}
                  {screen === "market" && <Marketplace />}
                  {screen === "inventory" && <Inventory />}
                  {screen === "beast" && <Beast />}
                  {screen === "leaderboard" && <Leaderboard />}
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
