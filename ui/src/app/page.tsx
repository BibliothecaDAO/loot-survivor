"use client";
import { useAccount, useConnectors } from "@starknet-react/core";
import { useState, useEffect, useMemo } from "react";
import { Button } from "./components/buttons/Button";
import HorizontalKeyboardControl from "./components/menu/HorizontalMenu";
import ActionsScreen from "./containers/ActionsScreen";
import AdventurerScreen from "./containers/AdventurerScreen";
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
import { Menu } from "./types";
import { useQueriesStore } from "./hooks/useQueryStore";
import Profile from "./containers/ProfileScreen";
import { DeathDialog } from "./components/adventurer/DeathDialog";
import { useMediaQuery } from "react-responsive";
import {
  CogIcon,
  MuteIcon,
  VolumeIcon,
  CartIcon,
  GithubIcon,
  RefreshIcon,
  CartIconSimple,
} from "./components/icons/Icons";
import Settings from "./components/navigation/Settings";
import MobileHeader from "./components/navigation/MobileHeader";
import Player from "./components/adventurer/Player";
import { useUiSounds } from "./hooks/useUiSound";
import { soundSelector } from "./hooks/useUiSound";
import { PenaltyCountDown } from "./components/CountDown";
import useCustomQuery from "./hooks/useCustomQuery";
import { getAdventurerById } from "./hooks/graphql/queries";

const allMenuItems: Menu[] = [
  { id: 1, label: "Start", screen: "start", disabled: false },
  { id: 2, label: "Play", screen: "play", disabled: false },
  { id: 3, label: "Inventory", screen: "inventory", disabled: false },
  { id: 4, label: "Upgrade", screen: "upgrade", disabled: false },
  { id: 5, label: "Leaderboard", screen: "leaderboard", disabled: false },
  { id: 6, label: "Encounters", screen: "encounters", disabled: false },
  { id: 7, label: "Guide", screen: "guide", disabled: false },
];

const mobileMenuItems: Menu[] = [
  { id: 1, label: "Start", screen: "start", disabled: false },
  { id: 2, label: "Play", screen: "play", disabled: false },
  { id: 3, label: "Inventory", screen: "inventory", disabled: false },
  { id: 4, label: "Upgrade", screen: "upgrade", disabled: false },
  { id: 5, label: "Encounters", screen: "encounters", disabled: false },
  { id: 6, label: "Guide", screen: "guide", disabled: false },
];

export default function Home() {
  const { disconnect } = useConnectors();
  const { account } = useAccount();
  const [isMuted, setIsMuted] = useState(false);

  const type = useLoadingStore((state) => state.type);
  const notificationData = useLoadingStore((state) => state.notificationData);
  const showNotification = useLoadingStore((state) => state.showNotification);
  const txAccepted = useLoadingStore((state) => state.txAccepted);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const calls = useTransactionCartStore((state) => state.calls);
  const connected = useUIStore((state) => state.connected);
  const setConnected = useUIStore((state) => state.setConnected);
  const screen = useUIStore((state) => state.screen);
  const setScreen = useUIStore((state) => state.setScreen);
  const handleOnboarded = useUIStore((state) => state.handleOnboarded);
  const deathDialog = useUIStore((state) => state.deathDialog);
  const displayHistory = useUIStore((state) => state.displayHistory);
  const setDisplayHistory = useUIStore((state) => state.setDisplayHistory);
  const displayCart = useUIStore((state) => state.displayCart);
  const setDisplayCart = useUIStore((state) => state.setDisplayCart);
  const mintAdventurer = useUIStore((state) => state.mintAdventurer);
  const setMintAdventurer = useUIStore((state) => state.setMintAdventurer);
  const { play: clickPlay } = useUiSounds(soundSelector.click);
  const setIndexer = useIndexerStore((state) => state.setIndexer);
  const [showDeathCount, setShowDeathCount] = useState(true);
  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);
  const hasStatUpgrades = useAdventurerStore(
    (state) => state.computed.hasStatUpgrades
  );
  const isAlive = useAdventurerStore((state) => state.computed.isAlive);
  const hasNoXp = useAdventurerStore((state) => state.computed.hasNoXp);

  const { data, refetch } = useQueriesStore();

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

  useCustomQuery(
    "adventurerByIdQuery",
    getAdventurerById,
    {
      id: adventurer?.id ?? 0,
    },
    txAccepted
  );

  useEffect(() => {
    return () => {
      stop();
    };
  }, [play, stop]);

  useEffect(() => {
    if (!account?.address) {
      setConnected(false);
    }
  }, [account, setConnected]);

  useMemo(() => {
    setIndexer(getGraphQLUrl());
  }, [setIndexer]);

  useEffect(() => {
    if ((isAlive && !hasStatUpgrades) || (isAlive && hasNoXp)) {
      setScreen("play");
    } else if (hasStatUpgrades) {
      setScreen("upgrade");
    } else if (!adventurer || !isAlive) {
      setScreen("start");
    }
  }, [hasStatUpgrades, isAlive, hasNoXp, adventurer]);

  useEffect(() => {
    if (mintAdventurer && data.adventurersByOwnerQuery) {
      const adventurers = data.adventurersByOwnerQuery.adventurers;
      setAdventurer(adventurers[adventurers.length - 1]);
      setScreen("play");
      setMintAdventurer(false);
    }
  }, [data.adventurersByOwnerQuery?.adventurers.length]);

  useEffect(() => {
    refetch("adventurersByOwnerQuery");
  }, [account]);

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  const mobileMenuDisabled = [
    false,
    hasStatUpgrades,
    false,
    !hasStatUpgrades,
    false,
    false,
  ];

  const allMenuDisabled = [
    false,
    hasStatUpgrades,
    false,
    !hasStatUpgrades,
    false,
    false,
    false,
  ];

  return (
    // <Maintenance />
    <main
      className={`min-h-screen container mx-auto flex flex-col p-4 pt-8 sm:p-10 `}
    >
      {connected ? (
        <>
          <div className="flex flex-col w-full">
            {isMobileDevice && <TxActivity />}
            <div className="flex flex-row justify-between">
              <span className="flex flex-row items-center gap-2 sm:gap-5 items-end">
                <h1 className="glitch m-0">Loot Survivor</h1>
                <PenaltyCountDown
                  lastDiscoveryTime={
                    data.latestDiscoveriesQuery?.discoveries[0]?.timestamp
                  }
                  lastBattleTime={data.lastBattleQuery?.battles[0]?.timestamp}
                />
              </span>
              <div className="flex flex-row items-center self-end gap-1 flex-wrap">
                
                <Button
                  onClick={() => {
                    setIsMuted(!isMuted);
                    clickPlay();
                  }}
                >
                  <div className="flex items-center justify-center">
                    {isMuted ? (
                      <MuteIcon className="w-4 h-4 sm:w-6 sm:h-6" />
                    ) : (
                      <VolumeIcon className="w-4 h-4 sm:w-6 sm:h-6" />
                    )}
                  </div>
                </Button>
                <Button onClick={async () => await refetch()}>
                  <RefreshIcon className="w-4 h-4 sm:w-6 sm:h-6" />
                </Button>
                {!isMobileDevice && account && calls.length > 0 && (
                  <button
                    onClick={() => {
                      setDisplayCart(!displayCart);
                      clickPlay();
                    }}
                    className="relative flex flex-row items-center gap-2 p-1 sm:p-2 bg-black border border-terminal-green text-xs sm:text-base"
                  >
                    <div className="w-4 h-4">
                      <CartIconSimple />
                    </div>
                    <p className="hidden sm:block">
                      {displayCart ? "Hide Cart" : "Show Cart"}
                    </p>
                  </button>
                )}
                {displayCart && <TransactionCart />}
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
                    <Button href="https://github.com/BibliothecaDAO/loot-survivor">
                      <GithubIcon className="w-6" />
                    </Button>
                  </>
                )}
                {account && displayHistory && <TransactionHistory />}
              </div>
            </div>
          </div>
          <div className="w-full h-4 sm:h-6 my-2 bg-terminal-green text-terminal-black px-4" >
          {!isMobileDevice && <TxActivity />}
          </div>
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
            <div className="fixed top-1/16 left-auto w-[90%] sm:left-3/8 sm:w-1/4 border rounded-lg border-terminal-green bg-terminal-black z-50">
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
            <div className="flex flex-col w-full">
              <>
                <div className="flex justify-center sm:justify-normal sm:pb-2">
                  <HorizontalKeyboardControl
                    buttonsData={
                      isMobileDevice ? mobileMenuItems : allMenuItems
                    }
                    onButtonClick={(value) => {
                      setScreen(value);
                    }}
                    disabled={
                      isMobileDevice ? mobileMenuDisabled : allMenuDisabled
                    }
                  />
                </div>

                {isMobileDevice && <MobileHeader />}

                {screen === "start" && <AdventurerScreen />}
                {screen === "play" && <ActionsScreen />}
                {screen === "inventory" && <InventoryScreen />}
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
