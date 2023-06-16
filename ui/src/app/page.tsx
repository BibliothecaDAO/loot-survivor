"use client";
import { useAccount, useConnectors } from "@starknet-react/core";
import { useState, useEffect, useMemo } from "react";
import { Button } from "./components/buttons/Button";
import HorizontalKeyboardControl from "./components/HorizontalMenu";
import Actions from "./components/actions/Actions";
import Marketplace from "./components/marketplace/Marketplace";
import Adventurer from "./components/start/Adventurer";
import Beast from "./components/beast/Beast";
import { displayAddress, padAddress } from "./lib/utils";
import Inventory from "./components/inventory/Inventory";
import TransactionHistory from "./components/navigation/TransactionHistory";
import TransactionCart from "./components/navigation/TransactionCart";
import Upgrade from "./components/Upgrade";
import Intro from "./components/intro/Intro";
import {
  AddDevnetEthButton,
  MintEthButton,
} from "./components/DevnetConnectors";
import Leaderboard from "./components/leaderboard/Leaderboard";
import { TxActivity } from "./components/navigation/TxActivity";
import useLoadingStore from "./hooks/useLoadingStore";
import useAdventurerStore from "./hooks/useAdventurerStore";
import useUIStore from "./hooks/useUIStore";
import useIndexerStore from "./hooks/useIndexerStore";
import useTransactionCartStore from "./hooks/useTransactionCartStore";
import { CSSTransition } from "react-transition-group";
import { NotificationDisplay } from "./components/NotificationDisplay";
import { useMusic } from "./hooks/useMusic";
import { testnet_addr } from "./lib/constants";
import { Menu, NullAdventurer } from "./types";
import { useQueriesStore } from "./hooks/useQueryStore";
import Profile from "./components/leaderboard/Profile";
import { DeathDialog } from "./components/DeathDialog";
import { Encounters } from "./components/Encounters";
import Guide from "./components/Guide";
import { processNotification } from "./components/NotificationDisplay";
import { DiscoveryDisplay } from "./components/actions/DiscoveryDisplay";
import useCustomQuery from "./hooks/useCustomQuery";
import {
  getBeastsByAdventurer,
  getAdventurerById,
  getBattleByTxHash,
  getDiscoveryByTxHash,
  getLatestMarketItems,
  getLatestMarketItemsNumber,
  getAdventurerByXP,
} from "./hooks/graphql/queries";
import { useMediaQuery } from "react-responsive";
import { CogIcon, MuteIcon, VolumeIcon } from "./components/Icons";
import Settings from "./components/Settings";
import MobileHeader from "./components/MobileHeader";
import Player from "./components/Player";
import { useUiSounds } from "./hooks/useUiSound";
import { soundSelector } from "./hooks/useUiSound";

export default function Home() {
  const { disconnect } = useConnectors();
  const { account } = useAccount();
  const [isMuted, setIsMuted] = useState(false);

  const type = useLoadingStore((state) => state.type);
  const pendingMessage = useLoadingStore((state) => state.pendingMessage);
  const notificationData = useLoadingStore((state) => state.notificationData);
  const showNotification = useLoadingStore((state) => state.showNotification);
  const deathMessage = useLoadingStore((state) => state.deathMessage);
  const setDeathMessage = useLoadingStore((state) => state.setDeathMessage);
  const txAccepted = useLoadingStore((state) => state.txAccepted);
  const hash = useLoadingStore((state) => state.hash);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const calls = useTransactionCartStore((state) => state.calls);
  const connected = useUIStore((state) => state.connected);
  const setConnected = useUIStore((state) => state.setConnected);
  const onboarded = useUIStore((state) => state.onboarded);
  const screen = useUIStore((state) => state.screen);
  const setScreen = useUIStore((state) => state.setScreen);
  const handleOnboarded = useUIStore((state) => state.handleOnboarded);
  const dialog = useUIStore((state) => state.dialog);
  // const dialog = true;
  const showDialog = useUIStore((state) => state.showDialog);
  const displayHistory = useUIStore((state) => state.displayHistory);
  const setDisplayHistory = useUIStore((state) => state.setDisplayHistory);
  const displayCart = useUIStore((state) => state.displayCart);
  const setDisplayCart = useUIStore((state) => state.setDisplayCart);
  const { play: clickPlay } = useUiSounds(soundSelector.click);
  const setIndexer = useIndexerStore((state) => state.setIndexer);
  const upgrade = adventurer?.upgrading;

  const { data, isDataUpdated, refetch, refetchFunctions } = useQueriesStore();

  const updatedAdventurer = data.adventurerByIdQuery
    ? data.adventurerByIdQuery.adventurers[0]
    : NullAdventurer;

  useCustomQuery(
    "beastsByAdventurerQuery",
    getBeastsByAdventurer,
    {
      adventurerId: adventurer?.id ?? 0,
    },
    txAccepted
  );
  const beasts = data.beastsByAdventurerQuery
    ? data.beastsByAdventurerQuery.beasts
    : [];

  useCustomQuery(
    "adventurerByIdQuery",
    getAdventurerById,
    {
      id: adventurer?.id ?? 0,
    },
    txAccepted
  );

  useCustomQuery(
    "battlesByTxHashQuery",
    getBattleByTxHash,
    {
      txHash: padAddress(hash),
    },
    txAccepted
    // hash !== ""
  );

  useCustomQuery(
    "discoveryByTxHashQuery",
    getDiscoveryByTxHash,
    {
      txHash: padAddress(hash),
    },
    txAccepted
    // hash !== ""
  );

  useCustomQuery(
    "latestMarketItemsNumberQuery",
    getLatestMarketItemsNumber,
    undefined,
    txAccepted
  );

  const latestMarketItemsNumber = data.latestMarketItemsNumberQuery
    ? data.latestMarketItemsNumberQuery.market[0]?.itemsNumber
    : [];

  useCustomQuery(
    "latestMarketItemsQuery",
    getLatestMarketItems,
    {
      itemsNumber: latestMarketItemsNumber,
    },
    txAccepted
  );

  useCustomQuery(
    "adventurersByXPQuery",
    getAdventurerByXP,
    undefined,
    txAccepted
  );

  useEffect(() => {
    if (updatedAdventurer?.id > 0) {
      setAdventurer(updatedAdventurer);
    }
  }, [updatedAdventurer]);

  const hasBeast = !!adventurer?.beastId;

  const playState = useMemo(
    () => ({
      isInBattle: hasBeast,
      isDead: false, // set this to true when player is dead
      isMuted: isMuted,
    }),
    [hasBeast, isMuted]
  );

  const { play, stop } = useMusic(playState, {
    volume: 0.5,
    loop: true,
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

  const [mobileMenu, setMobileMenu] = useState<Menu[]>([
    {
      id: 1,
      label: "Start",
      screen: "start",
    },
  ]);

  const adventurers = data.adventurersByOwnerQuery
    ? data.adventurersByOwnerQuery.adventurers
    : [];

  useEffect(() => {
    if (!adventurer || adventurer?.health == 0) {
      setScreen(menu[0].screen);
    }
  }, [adventurer]);

  useEffect(() => {
    if (data.battlesByTxHashQuery && isDataUpdated["battlesByTxHashQuery"]) {
      if (
        Array.isArray(data.battlesByTxHashQuery.battles) &&
        data.battlesByTxHashQuery.battles.some(
          (data: any) => data.attacker == "Beast" && data.targetHealth == 0
        )
      ) {
        const beast = data.beastByIdQuery ? data.beastByIdQuery.beasts[0] : [];
        const battles = data.battlesByBeastQuery
          ? data.battlesByBeastQuery.battles
          : [];
        const notification = processNotification(
          type,
          notificationData,
          adventurer,
          battles,
          hasBeast,
          beast,
          beasts
        );
        if (!deathMessage) {
          setDeathMessage(notification);
        }
        showDialog(true);
      }
    }
    // handle dead by discovering obstacle
    if (
      data.discoveryByTxHashQuery &&
      isDataUpdated["discoveryByTxHashQuery"]
    ) {
      if (
        data.discoveryByTxHashQuery.discoveries[0]?.discoveryType ==
          "Obstacle" &&
        adventurer?.health == 0
      ) {
        if (!deathMessage) {
          setDeathMessage(
            <DiscoveryDisplay
              discoveryData={notificationData}
              beasts={beasts}
            />
          );
        }
        showDialog(true);
      }
    }
    if (pendingMessage && isDataUpdated["adventurerByIdQuery"]) {
      if (
        (pendingMessage as string[]).includes("Equipping") &&
        adventurer?.health == 0
      ) {
        const beast = data.beastByIdQuery ? data.beastByIdQuery.beasts[0] : [];
        const battles = data.battlesByBeastQuery
          ? data.battlesByBeastQuery.battles
          : [];
        const notification = processNotification(
          type,
          notificationData,
          adventurer,
          battles,
          hasBeast,
          beast,
          beasts
        );
        console.log(notification);
        if (!deathMessage) {
          setDeathMessage(notification);
        }
        showDialog(true);
      }
    }
  }, [
    showNotification,
    data.battlesByTxHashQuery,
    data.discoveryByTxHashQuery,
  ]);

  useEffect(() => {
    if (!account?.address) {
      setConnected(false);
    }
  }, [account]);

  const goerli_graphql =
    "https://survivor-indexer.bibliothecadao.xyz:8080/goerli-graphql";
  const devnet_graphql =
    "https://survivor-indexer.bibliothecadao.xyz:8080/devnet-graphql";

  useMemo(() => {
    setIndexer(
      (account as any)?.provider?.baseUrl == testnet_addr ||
        (account as any)?.baseUrl == testnet_addr
        ? devnet_graphql
        : goerli_graphql
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

      let newMobileMenu: Menu[] = [
        {
          id: 1,
          label: "Start",
          screen: "start",
        },
      ];

      if (adventurer) {
        newMenu = [
          ...newMenu,
          {
            id: 2,
            label: "Actions",
            screen: "actions",
            disabled: hasBeast || upgrade || adventurer.health == 0,
          },
          {
            id: 3,
            label: "Market",
            screen: "market",
            disabled: hasBeast || adventurer.health == 0,
          },
          {
            id: 4,
            label: "Inventory",
            screen: "inventory",
            disabled: adventurer.health == 0,
          },
          {
            id: 5,
            label: "Beast",
            screen: "beast",
            disabled: upgrade || adventurer.health == 0,
          },
          {
            id: 6,
            label: "Leaderboard",
            screen: "leaderboard",
          },
          {
            id: 7,
            label: "Upgrade",
            screen: "upgrade",
            disabled: !upgrade,
          },
          {
            id: 8,
            label: "Encounters",
            screen: "encounters",
          },
          {
            id: 9,
            label: "Guide",
            screen: "guide",
          },
        ];

        newMobileMenu = [
          ...newMobileMenu,
          {
            id: 2,
            label: "Actions",
            screen: "actions",
            disabled: hasBeast || upgrade || adventurer.health == 0,
          },
          {
            id: 3,
            label: "Market",
            screen: "market",
            disabled: hasBeast || adventurer.health == 0 || !upgrade,
          },
          {
            id: 4,
            label: "Inventory",
            screen: "inventory",
            disabled: adventurer.health == 0,
          },
          {
            id: 5,
            label: "Beast",
            screen: "beast",
            disabled: upgrade || adventurer.health == 0,
          },
          {
            id: 6,
            label: "Upgrade",
            screen: "upgrade",
            disabled: !upgrade,
          },
        ];
      }
      setMenu(newMenu);
      setMobileMenu(newMobileMenu);
    }
  }, [adventurer, account, onboarded]);

  useEffect(() => {
    if (!onboarded) {
      if (adventurers.length == 0) {
        setMenu([
          {
            id: 1,
            label: "Start",
            screen: "start",
          },
        ]);
        setMobileMenu([
          {
            id: 1,
            label: "Start",
            screen: "start",
          },
        ]);
        setScreen(menu[0].screen);
      } else if (
        adventurers.length == 1 &&
        adventurer?.id &&
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
        setMobileMenu([
          {
            id: 1,
            label: "Actions",
            screen: "actions",
          },
        ]);
        setScreen("actions");
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
        setMobileMenu([
          {
            id: 1,
            label: "Actions",
            screen: "actions",
          },
        ]);
        setScreen("beast");
      } else {
        handleOnboarded();
        refetch("adventurersByOwnerQuery");
      }
    }
  }, [onboarded, adventurer, account]);

  useEffect(() => {
    if (upgrade && adventurer?.health !== 0) {
      setScreen("upgrade");
    }
  }, [upgrade]);

  // const beast = data.beastByIdQuery ? data.beastByIdQuery.beasts[0] : [];
  // const battleNotif = {
  //   data: [
  //     {
  //       adventurerId: 73,
  //       ambushed: null,
  //       attacker: "Adventurer",
  //       beastId: 223,
  //       damage: 6,
  //       fled: null,
  //       goldEarned: 0,
  //       targetHealth: 15,
  //       timestamp: "2023-06-04T10:56:19",
  //       txHash:
  //         "0x03201a416f4f1bef9fbdb1bec72003ad93432cd16e75fef91990c0be68bca2aa",
  //       xpEarned: 0,
  //     },
  //     {
  //       adventurerId: 73,
  //       ambushed: null,
  //       attacker: "Beast",
  //       beastId: 223,
  //       damage: 81,
  //       fled: null,
  //       goldEarned: 0,
  //       targetHealth: 0,
  //       timestamp: "2023-06-04T10:56:19",
  //       txHash:
  //         "0x03201a416f4f1bef9fbdb1bec72003ad93432cd16e75fef91990c0be68bca2aa",
  //       xpEarned: 15,
  //     },
  //   ],
  //   beast: beast,
  // };
  // const battles = data.battlesByBeastQuery
  //   ? data.battlesByBeastQuery.battles
  //   : [];
  // const notification = processNotification(
  //   "Attack",
  //   battleNotif,
  //   adventurer,
  //   battles,
  //   hasBeast,
  //   beast
  // );
  // setDeathMessage(notification);
  // const dialog = true;

  // fetch adventurers on app start and account switch
  useEffect(() => {
    refetch("adventurersByOwnerQuery");
  }, [account]);

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  return (
    // <Maintenance />
    <main
      className={`min-h-screen container mx-auto flex flex-col p-4 sm:p-10 overflow-hidden`}
    >
      {connected ? (
        <>
          <div className="flex flex-col w-full">
            {isMobileDevice && <TxActivity />}
            <div className="flex flex-row justify-between">
              <h1 className="glitch">Loot Survivor</h1>
              <div className="flex flex-row items-center self-end gap-2 flex-wrap">
                {!isMobileDevice && <TxActivity />}
                <button
                  onClick={() => {
                    setIsMuted(!isMuted);
                    clickPlay();
                  }}
                >
                  {isMuted ? (
                    <div className="flex items-center w-6 h-6">
                      <MuteIcon />
                    </div>
                  ) : (
                    <div className="flex items-center w-6 h-6">
                      <VolumeIcon />
                    </div>
                  )}
                </button>
                {account && calls.length > 0 && (
                  <>
                    <button
                      onClick={() => {
                        setDisplayCart(!displayCart);
                        clickPlay();
                      }}
                      className="relative flex px-1 sm:p-2 bg-black border border-terminal-green text-xs"
                    >
                      {displayCart ? "Hide Cart" : "Show Cart"}
                    </button>
                    {displayCart && <TransactionCart />}
                  </>
                )}
                {isMobileDevice ? (
                  <>
                    <button
                      className="w-6 h-6"
                      onClick={() => {
                        setScreen("settings");
                        clickPlay();
                      }}
                    >
                      <CogIcon />
                    </button>
                  </>
                ) : (
                  <>
                    {!isMobileDevice && account && (
                      <>
                        <Button
                          onClick={() => setDisplayHistory(!displayHistory)}
                        >
                          {displayHistory ? "Hide Ledger" : "Show Ledger"}
                        </Button>
                      </>
                    )}
                    {((account as any)?.provider?.baseUrl == testnet_addr ||
                      (account as any)?.baseUrl == testnet_addr) && (
                      <AddDevnetEthButton />
                    )}
                    {((account as any)?.provider?.baseUrl == testnet_addr ||
                      (account as any)?.baseUrl == testnet_addr) && (
                      <MintEthButton />
                    )}
                  </>
                )}
                {account && displayHistory && <TransactionHistory />}
                {account && (
                  <Button onClick={() => disconnect()}>
                    {displayAddress(account.address)}
                  </Button>
                )}
              </div>
            </div>
          </div>
          <div className="w-full h-4 sm:h-6 my-2 bg-terminal-green" />
          <CSSTransition
            in={
              showNotification &&
              Boolean(notificationData) &&
              (typeof notificationData === "object"
                ? "data" in notificationData
                  ? notificationData.data.length > 0
                  : true
                : true)
            }
            timeout={500}
            classNames="notification"
            unmountOnExit
          >
            <div className="fixed top-1/16 left-2/8  sm:left-3/8 sm:w-1/4 border rounded-lg border-terminal-green bg-terminal-black z-50">
              <NotificationDisplay
                type={type}
                notificationData={notificationData}
                hasBeast={hasBeast}
              />
            </div>
          </CSSTransition>

          {dialog && <DeathDialog />}

          {account ? (
            <div className="flex flex-col flex-grow w-full">
              <>
                <div className="gap-10 pb-2">
                  <HorizontalKeyboardControl
                    buttonsData={isMobileDevice ? mobileMenu : menu}
                    onButtonClick={(value) => {
                      setScreen(value);
                    }}
                  />
                </div>

                {isMobileDevice && <MobileHeader />}

                {screen === "start" && <Adventurer />}
                {screen === "actions" && <Actions />}
                {screen === "market" && <Marketplace />}
                {screen === "inventory" && <Inventory />}
                {screen === "beast" && <Beast />}
                {screen === "leaderboard" && <Leaderboard />}
                {screen === "upgrade" && <Upgrade />}
                {screen === "profile" && <Profile />}
                {screen === "encounters" && <Encounters />}
                {screen === "guide" && <Guide />}
                {screen === "settings" && <Settings />}
                {screen === "player" && <Player />}
              </>
            </div>
          ) : null}
        </>
      ) : (
        <Intro />
      )}
    </main>
  );
}
