"use client";
import { useAccount, useConnectors } from "@starknet-react/core";
import { useState, useEffect, useMemo, useCallback } from "react";
import { Button } from "./components/buttons/Button";
import HorizontalKeyboardControl from "./components/menu/HorizontalMenu";
import ActionsScreen from "./containers/ActionsScreen";
import MarketplaceScreen from "./containers/MarketplaceScreen";
import AdventurerScreen from "./containers/AdventurerScreen";
import BeastScreen from "./containers/BeastScreen";
import InventoryScreen from "./containers/InventoryScreen";
import LeaderboardScreen from "./containers/LeaderboardScreen";
import EncountersScreen from "./containers/EncountersScreen";
import GuideScreen from "./containers/GuideScreen";
import UpgradeScreen from "./containers/UpgradeScreen";
import { displayAddress } from "./lib/utils";
import TransactionHistory from "./components/navigation/TransactionHistory";
import TransactionCart from "./components/navigation/TransactionCart";
import Intro from "./components/intro/Intro";
import {
  AddDevnetEthButton,
  MintEthButton,
} from "./components/archived/DevnetConnectors";
import { TxActivity } from "./components/navigation/TxActivity";
import useLoadingStore from "./hooks/useLoadingStore";
import useAdventurerStore from "./hooks/useAdventurerStore";
import useUIStore from "./hooks/useUIStore";
import useIndexerStore from "./hooks/useIndexerStore";
import useTransactionCartStore from "./hooks/useTransactionCartStore";
import { CSSTransition } from "react-transition-group";
import { NotificationDisplay } from "./components/navigation/NotificationDisplay";
import { useMusic } from "./hooks/useMusic";
import { mainnet_addr, getGraphQLUrl } from "./lib/constants";
import { Menu, NullAdventurer, Call, Battle } from "./types";
import { useQueriesStore } from "./hooks/useQueryStore";
import Profile from "./containers/ProfileScreen";
import { DeathDialog } from "./components/adventurer/DeathDialog";
import { processNotification } from "./components/navigation/NotificationDisplay";
import { DiscoveryDisplay } from "./components/actions/DiscoveryDisplay";
import { useMediaQuery } from "react-responsive";
import {
  CogIcon,
  MuteIcon,
  VolumeIcon,
  CartIcon,
  SkullIcon,
  SmileIcon,
} from "./components/icons/Icons";
import Settings from "./components/navigation/Settings";
import MobileHeader from "./components/navigation/MobileHeader";
import Player from "./components/adventurer/Player";
import { useUiSounds } from "./hooks/useUiSound";
import { soundSelector } from "./hooks/useUiSound";
import { TutorialDialog } from "./components/tutorial/TutorialDialog";

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
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const calls = useTransactionCartStore((state) => state.calls);
  const connected = useUIStore((state) => state.connected);
  const setConnected = useUIStore((state) => state.setConnected);
  const onboarded = useUIStore((state) => state.onboarded);
  const screen = useUIStore((state) => state.screen);
  const setScreen = useUIStore((state) => state.setScreen);
  const handleOnboarded = useUIStore((state) => state.handleOnboarded);
  const deathDialog = useUIStore((state) => state.deathDialog);
  const showDeathDialog = useUIStore((state) => state.showDeathDialog);
  const tutorialDialog = useUIStore((state) => state.tutorialDialog);
  const showTutorialDialog = useUIStore((state) => state.showTutorialDialog);
  const displayHistory = useUIStore((state) => state.displayHistory);
  const setDisplayHistory = useUIStore((state) => state.setDisplayHistory);
  const displayCart = useUIStore((state) => state.displayCart);
  const setDisplayCart = useUIStore((state) => state.setDisplayCart);
  const { play: clickPlay } = useUiSounds(soundSelector.click);
  const setIndexer = useIndexerStore((state) => state.setIndexer);
  const statUpgrades = adventurer?.statUpgrades ?? 0;
  const [showDeathCount, setShowDeathCount] = useState(true);
  const [hasBeast, setHasBeast] = useState(false);

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
    return () => {
      stop();
    };
  }, [play, stop]);

  const { data, isDataUpdated, refetch } = useQueriesStore();

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

  const updatedAdventurer = data.adventurerByIdQuery
    ? data.adventurerByIdQuery.adventurers[0]
    : NullAdventurer;

  const adventurers = data.adventurersByOwnerQuery
    ? data.adventurersByOwnerQuery.adventurers
    : [];

  useEffect(() => {
    if (updatedAdventurer?.id ?? 0 > 0) {
      setAdventurer(updatedAdventurer);
    }
    if ((adventurer?.statUpgrades ?? 0) > 0) {
      setScreen("upgrade");
    }
  }, [updatedAdventurer, setAdventurer, setScreen, adventurer?.statUpgrades]);

  useEffect(() => {
    setHasBeast(!!(adventurer?.beastHealth ?? 0 > 0));
  }, [adventurer]);

  useEffect(() => {
    if (!adventurer || adventurer?.health == 0) {
      setScreen(menu[0].screen);
    }
  }, [adventurer, menu, setScreen]);

  useEffect(() => {
    const { battlesByTxHashQuery, discoveryByTxHashQuery, lastBattleQuery } =
      data;
    const battles = lastBattleQuery ? lastBattleQuery.battles : [];

    const setNotification = (
      type: any,
      notificationData: any,
      hasBeast: any
    ) => {
      const notification = processNotification(
        type,
        notificationData,
        battles,
        hasBeast
      );
      if (!deathMessage) {
        setDeathMessage(notification);
      }
      showDeathDialog(true);
    };

    const checkBattles = () => {
      if (!battlesByTxHashQuery || !isDataUpdated["battlesByTxHashQuery"]) {
        return;
      }
      const hasBeastAttacker = battlesByTxHashQuery.battles.some(
        (battle) => battle.attacker == "Beast" && adventurer?.health == 0
      );
      if (hasBeastAttacker) {
        setNotification(type, notificationData, hasBeast);
      }
    };

    const checkDiscovery = () => {
      if (!discoveryByTxHashQuery || !isDataUpdated["discoveryByTxHashQuery"]) {
        return;
      }
      const hasObstacle =
        discoveryByTxHashQuery.discoveries[0]?.discoveryType == "Obstacle" &&
        adventurer?.health == 0;
      if (hasObstacle && !deathMessage) {
        setDeathMessage(<DiscoveryDisplay discoveryData={notificationData} />);
        showDeathDialog(true);
      }
    };

    const checkEquipping = () => {
      if (!pendingMessage || !isDataUpdated["adventurerByIdQuery"]) {
        return;
      }
      const isEquipping =
        (pendingMessage as string[]).includes("Equipping") &&
        adventurer?.health == 0;
      if (isEquipping) {
        setNotification(type, notificationData, hasBeast);
      }
    };

    checkBattles();
    checkDiscovery();
    checkEquipping();
  }, [
    showNotification,
    data.battlesByTxHashQuery,
    data.discoveryByTxHashQuery,
    deathMessage,
    pendingMessage,
    isDataUpdated,
    adventurer,
    hasBeast,
    data,
    notificationData,
    setDeathMessage,
    showDeathDialog,
    type
  ]);

  useEffect(() => {
    if (!account?.address) {
      setConnected(false);
    }
  }, [account, setConnected]);

  useMemo(() => {
    setIndexer(getGraphQLUrl());
  }, [setIndexer]);

  useEffect(() => {
    if (onboarded) {
      const commonMenuItems = (isMobile = false) => [
        {
          id: isMobile ? 2 : 1,
          label: "Start",
          screen: "start",
          disabled: false,
        },
        ...(adventurer
          ? [
            {
              id: isMobile ? 3 : 2,
              label: "Play",
              screen: "play",
              disabled:
                statUpgrades > 0 || adventurer.health == 0,
            },
            {
              id: isMobile ? 4 : 3,
              label: "Inventory",
              screen: "inventory",
              disabled: adventurer.health == 0,
            },
            // {
            //   id: isMobile ? 5 : 4,
            //   label: "Beast",
            //   screen: "beast",
            //   disabled: statUpgrades > 0 || adventurer.health == 0,
            // },
            {
              id: isMobile ? 6 : 5,
              label: statUpgrades > 0 ? <span>Upgrade!</span> : "Upgrade",
              screen: "upgrade",
              disabled: !(statUpgrades > 0),
            },
            // {
            //   id: isMobile ? 7 : 6,
            //   label: "Market",
            //   screen: "market",
            //   disabled:
            //     !(statUpgrades > 0) ||
            //     hasBeast ||
            //     adventurer.health == 0 ||
            //     purchaseExists(),
            // },
          ]
          : []),
        ...(isMobile
          ? []
          : [
            {
              id: 7,
              label: "Leaderboard",
              screen: "leaderboard",
              disabled: false,
            },
            {
              id: 8,
              label: "Encounters",
              screen: "encounters",
              disabled: false,
            },
            {
              id: 9,
              label: "Guide",
              screen: "guide",
              disabled: false,
            },
          ]),
      ];

      const newMenu: any = adventurer
        ? commonMenuItems()
        : [{ id: 1, label: "Start", screen: "start", disabled: false }];

      const newMobileMenu: any = adventurer
        ? commonMenuItems(true)
        : [{ id: 1, label: "Start", screen: "start", disabled: false }];

      setMenu(newMenu);
      setMobileMenu(newMobileMenu);
    }
  }, [adventurer, account, onboarded, hasBeast, statUpgrades]);

  useEffect(() => {
    if (onboarded) return;

    const createMenu = (label: string, screen: any) => {
      const menuData = {
        id: 1,
        label: label,
        screen: screen,
      };

      setMenu([menuData]);
      setMobileMenu([menuData]);
      setScreen(screen);
      showTutorialDialog(true);
    };

    const hasAdventurers = adventurers.length > 0;
    const adventurerExistsAndHasXP = adventurer?.xp === 0;
    const beastHealth = adventurer?.beastHealth ?? 0;
    const statUpgrades = adventurer?.statUpgrades ?? 0;

    if (!hasAdventurers) {
      createMenu("Start", "start");
    } else if (adventurerExistsAndHasXP) {
      createMenu("Play", "play")
    } else {
      handleOnboarded();
      refetch("adventurersByOwnerQuery");
    }
  }, [onboarded, adventurer, account, adventurers.length, handleOnboarded, refetch, setScreen, showTutorialDialog]);

  // useEffect(() => {
  //   if (statUpgrades > 0 && adventurer?.health !== 0) {
  //     setScreen("upgrade");
  //   }
  // }, [statUpgrades, adventurer?.health, setScreen]);

  // fetch adventurers on app start and account switch
  useEffect(() => {
    refetch("adventurersByOwnerQuery");
  }, [account, refetch]);

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
                <div
                  className="flex flex-row items-center gap-1 p-1 sm:px-2 border border-terminal-green cursor-pointer"
                  onClick={() => setShowDeathCount(!showDeathCount)}
                >
                  {showDeathCount && (
                    <>
                      <div className="flex items-center w-4 h-4 sm:w-5">
                        <SkullIcon />
                      </div>
                      <p className="text-red-500 sm:text-xl">20</p>
                    </>
                  )}
                  {!showDeathCount && (
                    <>
                      <div className="flex items-center w-4 h-4 sm:w-5">
                        <SmileIcon />
                      </div>
                      <p className="text-terminal-green sm:text-xl">20</p>
                    </>
                  )}
                </div>
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
                      className="relative flex flex-row items-center gap-2 p-1 sm:p-2 bg-black border border-terminal-green text-xs sm:text-base"
                    >
                      <div className="w-4 h-4">
                        <CartIcon />
                      </div>
                      <p className="hidden sm:block">
                        {displayCart ? "Hide Cart" : "Show Cart"}
                      </p>
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
                    {((account as any)?.provider?.baseUrl == mainnet_addr ||
                      (account as any)?.baseUrl == mainnet_addr) && (
                        <AddDevnetEthButton />
                      )}
                    {((account as any)?.provider?.baseUrl == mainnet_addr ||
                      (account as any)?.baseUrl == mainnet_addr) && (
                        <MintEthButton />
                      )}
                    {account && (
                      <Button onClick={() => disconnect()}>
                        {displayAddress(account.address)}
                      </Button>
                    )}
                  </>
                )}
                {account && displayHistory && <TransactionHistory />}
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

          {deathDialog && <DeathDialog />}

          {/* {!onboarded && tutorialDialog && <TutorialDialog />} */}

          {account ? (
            <div className="flex flex-col flex-grow w-full">
              <>
                <div className="flex justify-center sm:justify-normal sm:pb-2">
                  <HorizontalKeyboardControl
                    buttonsData={isMobileDevice ? mobileMenu : menu}
                    onButtonClick={(value) => {
                      setScreen(value);
                    }}
                  />
                </div>

                {isMobileDevice && <MobileHeader />}

                {screen === "start" && <AdventurerScreen />}
                {screen === "play" && <ActionsScreen />}
                {screen === "market" && <MarketplaceScreen />}
                {screen === "inventory" && <InventoryScreen />}
                {screen === "beast" && <BeastScreen />}
                {screen === "leaderboard" && <LeaderboardScreen />}
                {screen === "upgrade" && <UpgradeScreen />}
                {screen === "profile" && <Profile />}
                {screen === "encounters" && <EncountersScreen />}
                {screen === "guide" && <GuideScreen />}
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
