"use client";
import {
  useAccount,
  useConnectors,
  useNetwork,
  useProvider,
  useContractWrite,
  useTransactionManager,
} from "@starknet-react/core";
import { constants } from "starknet";
import { useState, useEffect, useMemo, useRef, useCallback } from "react";
import { Button } from "./components/buttons/Button";
import HorizontalKeyboardControl from "./components/menu/HorizontalMenu";
import ActionsScreen from "./containers/ActionsScreen";
import AdventurerScreen from "./containers/AdventurerScreen";
import InventoryScreen from "./containers/InventoryScreen";
import LeaderboardScreen from "./containers/LeaderboardScreen";
import EncountersScreen from "./containers/EncountersScreen";
import GuideScreen from "./containers/GuideScreen";
import UpgradeScreen from "./containers/UpgradeScreen";
import { displayAddress, padAddress } from "./lib/utils";
import TransactionHistory from "./components/navigation/TransactionHistory";
import TransactionCart from "./components/navigation/TransactionCart";
import Intro from "./components/intro/Intro";
import { TxActivity } from "./components/navigation/TxActivity";
import useLoadingStore from "./hooks/useLoadingStore";
import useAdventurerStore from "./hooks/useAdventurerStore";
import useUIStore from "./hooks/useUIStore";
import useTransactionCartStore from "./hooks/useTransactionCartStore";
import { NotificationDisplay } from "./components/notifications/NotificationDisplay";
import { useMusic } from "./hooks/useMusic";
import { Menu, NullAdventurer, NullDiscovery } from "./types";
import { useQueriesStore } from "./hooks/useQueryStore";
import Profile from "./containers/ProfileScreen";
import { DeathDialog } from "./components/adventurer/DeathDialog";
import WalletSelect from "./components/intro/WalletSelect";
import {
  CogIcon,
  MuteIcon,
  VolumeIcon,
  GithubIcon,
  RefreshIcon,
  CartIconSimple,
  ArcadeIcon,
} from "./components/icons/Icons";
import Settings from "./components/navigation/Settings";
import MobileHeader from "./components/navigation/MobileHeader";
import Player from "./components/adventurer/Player";
import { useUiSounds } from "./hooks/useUiSound";
import { soundSelector } from "./hooks/useUiSound";
import { PenaltyCountDown } from "./components/CountDown";
import useCustomQuery from "./hooks/useCustomQuery";
import {
  getAdventurerById,
  getAdventurersByOwner,
  getLatestDiscoveries,
  getLastBeastDiscovery,
  getBeast,
  getBattlesByBeast,
  getItemsByAdventurer,
  getLatestMarketItems,
} from "./hooks/graphql/queries";
import { ArcadeDialog } from "./components/ArcadeDialog";
import NetworkSwitchError from "./components/navigation/NetworkSwitchError";
import { syscalls } from "./lib/utils/syscalls";
import { useContracts } from "./hooks/useContracts";
import { Maintenance } from "./components/archived/Maintenance";
import { set } from "lodash";
import LootIconLoader from "./components/icons/Loader";

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
  const { disconnect, connectors } = useConnectors();
  const { chain } = useNetwork();
  const { provider } = useProvider();
  const disconnected = useUIStore((state) => state.disconnected);
  const setDisconnected = useUIStore((state) => state.setDisconnected);
  const { account, status, isConnected } = useAccount();
  const isMuted = useUIStore((state) => state.isMuted);
  const setIsMuted = useUIStore((state) => state.setIsMuted);
  const [introComplete, setIntroComplete] = useState(false);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const calls = useTransactionCartStore((state) => state.calls);
  const screen = useUIStore((state) => state.screen);
  const setScreen = useUIStore((state) => state.setScreen);
  const deathDialog = useUIStore((state) => state.deathDialog);
  const displayHistory = useUIStore((state) => state.displayHistory);
  const setDisplayHistory = useUIStore((state) => state.setDisplayHistory);
  const displayCart = useUIStore((state) => state.displayCart);
  const setDisplayCart = useUIStore((state) => state.setDisplayCart);
  const setMintAdventurer = useUIStore((state) => state.setMintAdventurer);
  const { play: clickPlay } = useUiSounds(soundSelector.click);
  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);
  const hasStatUpgrades = useAdventurerStore(
    (state) => state.computed.hasStatUpgrades
  );
  const isAlive = useAdventurerStore((state) => state.computed.isAlive);
  const hasNoXp = useAdventurerStore((state) => state.computed.hasNoXp);
  const owner = account?.address ? padAddress(account.address) : "";
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const setIsWrongNetwork = useUIStore((state) => state.setIsWrongNetwork);
  const displayHistoryButtonRef = useRef<HTMLButtonElement>(null);
  const displayCartButtonRef = useRef<HTMLButtonElement>(null);

  const arcadeDialog = useUIStore((state) => state.arcadeDialog);
  const showArcadeDialog = useUIStore((state) => state.showArcadeDialog);

  const { gameContract, lordsContract } = useContracts();
  const { addTransaction } = useTransactionManager();
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const startLoading = useLoadingStore((state) => state.startLoading);
  const stopLoading = useLoadingStore((state) => state.stopLoading);
  const setTxHash = useLoadingStore((state) => state.setTxHash);
  const { writeAsync } = useContractWrite({ calls });
  const setEquipItems = useUIStore((state) => state.setEquipItems);
  const setDropItems = useUIStore((state) => state.setDropItems);
  const setDeathMessage = useLoadingStore((state) => state.setDeathMessage);
  const showDeathDialog = useUIStore((state) => state.showDeathDialog);
  const resetNotification = useLoadingStore((state) => state.resetNotification);

  const {
    data,
    refetch,
    resetData,
    setData,
    isLoading,
    setIsLoading,
    setNotLoading,
  } = useQueriesStore();

  const { spawn, explore, attack, flee, upgrade, multicall } = syscalls({
    gameContract,
    lordsContract,
    addTransaction,
    account,
    queryData: data,
    resetData,
    setData,
    adventurer,
    addToCalls,
    calls,
    handleSubmitCalls,
    startLoading,
    stopLoading,
    setTxHash,
    writeAsync,
    setEquipItems,
    setDropItems,
    setDeathMessage,
    showDeathDialog,
    resetNotification,
    setScreen,
    setAdventurer,
    setMintAdventurer,
  });

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

  const handleIntroComplete = () => {
    setIntroComplete(true);
  };

  const ownerVariables = useMemo(() => {
    return {
      owner: owner,
    };
  }, [owner]);

  const adventurersData = useCustomQuery(
    "adventurersByOwnerQuery",
    getAdventurersByOwner,
    ownerVariables,
    owner === ""
  );

  const adventurerVariables = useMemo(() => {
    return {
      id: adventurer?.id ?? 0,
    };
  }, [adventurer?.id ?? 0]);

  useCustomQuery("adventurerByIdQuery", getAdventurerById, adventurerVariables);

  useCustomQuery(
    "latestDiscoveriesQuery",
    getLatestDiscoveries,
    adventurerVariables
  );

  useCustomQuery(
    "itemsByAdventurerQuery",
    getItemsByAdventurer,
    adventurerVariables
  );

  useCustomQuery(
    "latestMarketItemsQuery",
    getLatestMarketItems,
    adventurerVariables
  );

  const lastBeastData = useCustomQuery(
    "lastBeastQuery",
    getLastBeastDiscovery,
    adventurerVariables
  );

  const beastVariables = useMemo(() => {
    return {
      adventurerId: adventurer?.id ?? 0,
      beast: lastBeastData?.discoveries[0]?.entity,
      seed: lastBeastData?.discoveries[0]?.seed,
    };
  }, [
    adventurer?.id ?? 0,
    lastBeastData?.discoveries[0]?.entity,
    lastBeastData?.discoveries[0]?.seed,
  ]);

  useCustomQuery("beastQuery", getBeast, beastVariables);

  useCustomQuery("battlesByBeastQuery", getBattlesByBeast, beastVariables);

  const handleSwitchAdventurer = async (adventurerId: number) => {
    setIsLoading();
    const newAdventurerData = await refetch("adventurerByIdQuery", {
      id: adventurerId,
    });
    const newLatestDiscoveriesData = await refetch("latestDiscoveriesQuery", {
      id: adventurerId,
    });
    const newAdventurerItemsData = await refetch("itemsByAdventurerQuery", {
      id: adventurerId,
    });
    const newMarketItemsData = await refetch("latestMarketItemsQuery", {
      id: adventurerId,
    });
    const newLastBeastData = await refetch("lastBeastQuery", {
      id: adventurerId,
    });
    const newBeastData = await refetch("beastQuery", {
      adventurerId: adventurerId,
      beast: newLastBeastData.discoveries[0]?.entity,
      seed: newLastBeastData.discoveries[0]?.seed,
    });
    const newBattlesByBeastData = await refetch("battlesByBeastQuery", {
      adventurerId: adventurerId,
      beast: newLastBeastData.discoveries[0]?.entity,
      seed: newLastBeastData.discoveries[0]?.seed,
    });
    setData("adventurerByIdQuery", newAdventurerData);
    setData("latestDiscoveriesQuery", newLatestDiscoveriesData);
    setData("itemsByAdventurerQuery", newAdventurerItemsData);
    setData("latestMarketItemsQuery", newMarketItemsData);
    setData("lastBeastQuery", newLastBeastData);
    setData("beastQuery", newBeastData);
    setData("battlesByBeastQuery", newBattlesByBeastData);
    setNotLoading();
  };

  useEffect(() => {
    return () => {
      stop();
    };
  }, [play, stop]);

  useEffect(() => {
    const isWrongNetwork = chain?.id !== constants.StarknetChainId.SN_GOERLI;
    setIsWrongNetwork(isWrongNetwork);
  }, [chain, provider, isConnected]);

  // Initialize adventurers from owner
  useEffect(() => {
    if (adventurersData) {
      setData("adventurersByOwnerQuery", adventurersData);
    }
  }, [adventurersData]);

  useEffect(() => {
    if ((isAlive && !hasStatUpgrades) || (isAlive && hasNoXp)) {
      setScreen("play");
    } else if (hasStatUpgrades) {
      setScreen("upgrade");
    } else if (!adventurer || !isAlive) {
      setScreen("start");
    }
  }, [hasStatUpgrades, isAlive, hasNoXp, adventurer]);

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

  useEffect(() => {
    if (isConnected) {
      setDisconnected(false);
    }
  }, [isConnected]);

  if (!isConnected && introComplete && disconnected) {
    return <WalletSelect />;
  }

  return (
    // <Maintenance />
    <main
      className={`min-h-screen container mx-auto flex flex-col p-4 pt-8 sm:p-8 lg:p-10 2xl:p-20 `}
    >
      {introComplete ? (
        <>
          <div className="flex flex-col w-full">
            <NetworkSwitchError isWrongNetwork={isWrongNetwork} />

            <div className="sm:hidden">
              <TxActivity />
            </div>
            <div className="flex flex-row justify-between">
              <span className="flex flex-row items-center gap-2 sm:gap-5">
                <h1 className="glitch m-0 text-lg sm:text-4xl">
                  Loot Survivor
                </h1>
                <PenaltyCountDown
                  lastDiscoveryTime={
                    data.latestDiscoveriesQuery?.discoveries[0]?.timestamp
                  }
                  lastBattleTime={data.lastBattleQuery?.battles[0]?.timestamp}
                />
              </span>
              <div className="flex flex-row items-center self-end gap-1 flex-wrap">
                <Button
                  onClick={() => showArcadeDialog(!arcadeDialog)}
                  disabled={isWrongNetwork}
                >
                  <ArcadeIcon className="w-4 sm:w-8 justify-center" />
                </Button>
                <Button
                  onClick={() => {
                    setIsMuted(!isMuted);
                    clickPlay();
                  }}
                  className="hidden sm:block"
                >
                  <div className="flex items-center justify-center">
                    {isMuted ? (
                      <MuteIcon className="w-4 h-4 sm:w-6 sm:h-6" />
                    ) : (
                      <VolumeIcon className="w-4 h-4 sm:w-6 sm:h-6" />
                    )}
                  </div>
                </Button>
                {account && calls.length > 0 && (
                  <button
                    ref={displayCartButtonRef}
                    onClick={() => {
                      setDisplayCart(!displayCart);
                      clickPlay();
                    }}
                    className="relative flex flex-row items-center justify-center gap-2 p-1 sm:p-2 bg-black border border-terminal-green text-xs sm:text-base"
                  >
                    <CartIconSimple className="w-4 h-4" />
                    <p className="hidden sm:block">
                      {displayCart ? "Hide Cart" : "Show Cart"}
                    </p>
                  </button>
                )}
                {displayCart && (
                  <TransactionCart
                    buttonRef={displayCartButtonRef}
                    multicall={multicall}
                  />
                )}
                <div className="flex items-center sm:hidden">
                  <button
                    className="w-6 h-6"
                    onClick={() => {
                      setScreen("settings");
                      clickPlay();
                    }}
                  >
                    <CogIcon />
                  </button>
                </div>
                <div className="hidden sm:block sm:flex sm:flex-row sm:items-center sm:gap-1">
                  {account && (
                    <>
                      <Button
                        ref={displayHistoryButtonRef}
                        onClick={() => {
                          setDisplayHistory(!displayHistory);
                        }}
                      >
                        {displayHistory ? "Hide Ledger" : "Show Ledger"}
                      </Button>
                    </>
                  )}

                  <Button
                    onClick={() => {
                      disconnect();
                      resetData();
                      setAdventurer(NullAdventurer);
                      setDisconnected(true);
                    }}
                  >
                    {account ? displayAddress(account.address) : "Connect"}
                  </Button>

                  <Button href="https://github.com/BibliothecaDAO/loot-survivor">
                    <GithubIcon className="w-6" />
                  </Button>
                </div>
                {account && displayHistory && (
                  <TransactionHistory buttonRef={displayHistoryButtonRef} />
                )}
              </div>
            </div>
          </div>
          <div className="w-full h-4 sm:h-6 my-2 bg-terminal-green text-terminal-black px-4">
            <div className="hidden sm:block">
              <TxActivity />
            </div>
          </div>
          <NotificationDisplay />

          {deathDialog && <DeathDialog />}

          {status == "connected" && arcadeDialog && <ArcadeDialog />}

          {/* {!onboarded && tutorialDialog && <TutorialDialog />} */}

          {introComplete ? (
            <div className="flex flex-col w-full">
              <>
                <div className="sm:hidden flex justify-center sm:justify-normal sm:pb-2">
                  <HorizontalKeyboardControl
                    buttonsData={mobileMenuItems}
                    onButtonClick={(value) => {
                      setScreen(value);
                    }}
                    disabled={mobileMenuDisabled}
                  />
                </div>
                <div className="hidden sm:block flex justify-center sm:justify-normal sm:pb-2">
                  <HorizontalKeyboardControl
                    buttonsData={allMenuItems}
                    onButtonClick={(value) => {
                      setScreen(value);
                    }}
                    disabled={allMenuDisabled}
                  />
                </div>

                <div className="sm:hidden">
                  <MobileHeader />
                </div>

                {/* <div className="overflow-y-auto h-[460px] sm:h-full"> */}
                {isLoading.global ? (
                  <div className="fixed top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
                    <LootIconLoader size="w-10" />
                  </div>
                ) : (
                  <>
                    {screen === "start" && (
                      <AdventurerScreen
                        spawn={spawn}
                        handleSwitchAdventurer={handleSwitchAdventurer}
                      />
                    )}
                    {screen === "play" && (
                      <ActionsScreen
                        explore={explore}
                        attack={attack}
                        flee={flee}
                      />
                    )}
                    {screen === "inventory" && <InventoryScreen />}
                    {screen === "leaderboard" && <LeaderboardScreen />}
                    {screen === "upgrade" && (
                      <UpgradeScreen upgrade={upgrade} />
                    )}
                    {screen === "profile" && <Profile />}
                    {screen === "encounters" && <EncountersScreen />}
                    {screen === "guide" && <GuideScreen />}
                    {screen === "settings" && <Settings />}
                    {screen === "player" && <Player />}
                    {screen === "wallet" && <WalletSelect />}
                  </>
                )}
                {/* </div> */}
              </>
            </div>
          ) : null}
        </>
      ) : (
        <Intro onIntroComplete={handleIntroComplete} />
      )}
    </main>
  );
}
