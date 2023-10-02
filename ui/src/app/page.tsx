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
import { useState, useEffect, useMemo, useRef } from "react";
import { Button } from "./components/buttons/Button";
import ActionsScreen from "./containers/ActionsScreen";
import AdventurerScreen from "./containers/AdventurerScreen";
import InventoryScreen from "./containers/InventoryScreen";
import LeaderboardScreen from "./containers/LeaderboardScreen";
import EncountersScreen from "./containers/EncountersScreen";
import GuideScreen from "./containers/GuideScreen";
import UpgradeScreen from "./containers/UpgradeScreen";
import { displayAddress, padAddress, formatNumber } from "./lib/utils";
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
import { Menu, NullAdventurer } from "./types";
import { useQueriesStore } from "./hooks/useQueryStore";
import Profile from "./containers/ProfileScreen";
import { DeathDialog } from "./components/adventurer/DeathDialog";
import WalletSelect from "./components/intro/WalletSelect";
import {
  SettingsIcon,
  SoundOnIcon,
  SoundOffIcon,
  GithubIcon,
  CartIcon,
  ArcadeIcon,
} from "./components/icons/Icons";
import Lords from "../../public/icons/lords.svg";
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
import { TopUpDialog } from "./components/TopUpDialog";
import NetworkSwitchError from "./components/navigation/NetworkSwitchError";
import { syscalls } from "./lib/utils/syscalls";
import { useContracts } from "./hooks/useContracts";
import { useBalance } from "@starknet-react/core";
import { ArcadeIntro } from "./components/intro/ArcadeIntro";
import Logo from "../../public/icons/logo.svg";
import ScreenMenu from "./components/menu/ScreenMenu";

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
  const { chain } = useNetwork();
  const { provider } = useProvider();
  const disconnected = useUIStore((state) => state.disconnected);
  const setDisconnected = useUIStore((state) => state.setDisconnected);
  const { account, address, status, isConnected } = useAccount();
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
  const owner = account?.address ? padAddress(account.address) : "";
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const setIsWrongNetwork = useUIStore((state) => state.setIsWrongNetwork);
  const displayHistoryButtonRef = useRef<HTMLButtonElement>(null);
  const displayCartButtonRef = useRef<HTMLButtonElement>(null);

  const arcadeDialog = useUIStore((state) => state.arcadeDialog);
  const showArcadeDialog = useUIStore((state) => state.showArcadeDialog);
  const arcadeIntro = useUIStore((state) => state.arcadeIntro);
  const showArcadeIntro = useUIStore((state) => state.showArcadeIntro);
  const topUpDialog = useUIStore((state) => state.topUpDialog);
  const showTopUpDialog = useUIStore((state) => state.showTopUpDialog);
  const setTopUpAccount = useUIStore((state) => state.setTopUpAccount);
  const setEstimatingFee = useUIStore((state) => state.setEstimatingFee);
  const { gameContract, lordsContract, ethContract } = useContracts();
  const { addTransaction } = useTransactionManager();
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const startLoading = useLoadingStore((state) => state.startLoading);
  const stopLoading = useLoadingStore((state) => state.stopLoading);
  const pendingMessage = useLoadingStore((state) => state.pendingMessage);
  const setTxHash = useLoadingStore((state) => state.setTxHash);
  const { writeAsync } = useContractWrite({ calls });
  const setEquipItems = useUIStore((state) => state.setEquipItems);
  const setDropItems = useUIStore((state) => state.setDropItems);
  const setDeathMessage = useLoadingStore((state) => state.setDeathMessage);
  const showDeathDialog = useUIStore((state) => state.showDeathDialog);
  const resetNotification = useLoadingStore((state) => state.resetNotification);
  const setStartOption = useUIStore((state) => state.setStartOption);

  const lordsBalance = useBalance({
    token: lordsContract?.address,
    address,
  });

  const ethBalance = useBalance({
    token: ethContract?.address,
    address,
  });

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
    setStartOption,
    ethBalance: ethBalance.data?.value ?? BigInt(0),
    showTopUpDialog,
    setTopUpAccount,
    setEstimatingFee,
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

  const spawnLoader =
    pendingMessage &&
    (pendingMessage === "Spawning Adventurer" ||
      pendingMessage.includes("Spawning Adventurer"));

  return (
    // <Maintenance />
    <main
      className={`min-h-screen container mx-auto flex flex-col sm:pt-8 sm:p-8 lg:p-10 2xl:p-20 `}
    >
      {introComplete ? (
        <>
          <div className="flex flex-col w-full">
            <NetworkSwitchError isWrongNetwork={isWrongNetwork} />
            {!spawnLoader && (
              <div className="sm:hidden">
                <TxActivity />
              </div>
            )}
            <div className="flex flex-row justify-between px-1  ">
              <div className="flex flex-row items-center gap-2 sm:gap-5">
                <Logo className="fill-current w-24 md:w-32 xl:w-40 2xl:w-64" />
              </div>
              <div className="flex flex-row items-center self-end sm:gap-1 space-x-1 self-center">
                {adventurer?.id && (
                  <PenaltyCountDown
                    lastDiscoveryTime={
                      data.latestDiscoveriesQuery?.discoveries[0]?.timestamp
                    }
                    lastBattleTime={data.lastBattleQuery?.battles[0]?.timestamp}
                    dataLoading={isLoading.global}
                  />
                )}
                <Button size={"xs"} variant={"outline"} className="self-center">
                  <span className="flex flex-row items-center justify-between w-full">
                    <Lords className="self-center sm:w-5 sm:h-5  h-3 w-3 fill-current mr-1" />
                    <p>
                      {formatNumber(
                        parseInt(lordsBalance.data?.formatted ?? "0")
                      )}
                    </p>
                  </span>
                </Button>
                <Button
                  size={"xs"}
                  variant={"outline"}
                  onClick={() => showArcadeIntro(!arcadeIntro)}
                  disabled={isWrongNetwork}
                >
                  <ArcadeIcon className="sm:w-5 sm:h-5  h-3 w-3 justify-center fill-current mr-2" />
                  <span className="hidden sm:block">arcade account</span>
                </Button>
                <Button
                  size={"xs"}
                  variant={"outline"}
                  onClick={() => {
                    setIsMuted(!isMuted);
                    clickPlay();
                  }}
                  className="hidden sm:block"
                >
                  {isMuted ? (
                    <SoundOffIcon className="sm:w-5 sm:h-5 h-3 w-3 justify-center fill-current" />
                  ) : (
                    <SoundOnIcon className="sm:w-5 sm:h-5 h-3 w-3 justify-center fill-current" />
                  )}
                </Button>
                {account && (
                  <Button
                    variant={"outline"}
                    size={"xs"}
                    ref={displayCartButtonRef}
                    onClick={() => {
                      setDisplayCart(!displayCart);
                      clickPlay();
                    }}
                  >
                    <CartIcon className="sm:w-5 sm:h-5 h-3 w-3 fill-current" />
                  </Button>
                )}
                {displayCart && (
                  <TransactionCart
                    buttonRef={displayCartButtonRef}
                    multicall={multicall}
                  />
                )}
                <div className="flex items-center sm:hidden">
                  <Button
                    size={"xs"}
                    variant={"outline"}
                    onClick={() => {
                      setScreen("settings");
                      clickPlay();
                    }}
                  >
                    <SettingsIcon className="fill-current h-3 w-3" />
                  </Button>
                </div>
                <div className="hidden sm:block sm:flex sm:flex-row sm:items-center sm:gap-1">
                  {account && (
                    <>
                      <Button
                        variant={"outline"}
                        size={"xs"}
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
                    variant={"outline"}
                    size={"sm"}
                    onClick={() => {
                      disconnect();
                      resetData();
                      setAdventurer(NullAdventurer);
                      setDisconnected(true);
                    }}
                  >
                    {account ? displayAddress(account.address) : "Connect"}
                  </Button>

                  <Button
                    variant={"outline"}
                    size={"sm"}
                    href="https://github.com/BibliothecaDAO/loot-survivor"
                  >
                    <GithubIcon className="w-6 fill-current" />
                  </Button>
                </div>
                {account && displayHistory && (
                  <TransactionHistory buttonRef={displayHistoryButtonRef} />
                )}
              </div>
            </div>
          </div>
          <div className="w-full h-1 sm:h-6 sm:my-2 bg-terminal-green text-terminal-black px-4">
            {!spawnLoader && (
              <div className="hidden sm:block">
                <TxActivity />
              </div>
            )}
          </div>
          <NotificationDisplay />

          {deathDialog && <DeathDialog />}
          {status == "connected" && arcadeIntro && <ArcadeIntro />}
          {status == "connected" && arcadeDialog && <ArcadeDialog />}
          {status == "connected" && topUpDialog && <TopUpDialog />}

          {introComplete ? (
            <div className="flex flex-col w-full">
              <>
                <div className="sm:hidden flex  sm:justify-normal sm:pb-2">
                  <ScreenMenu
                    buttonsData={mobileMenuItems}
                    onButtonClick={(value) => {
                      setScreen(value);
                    }}
                    disabled={mobileMenuDisabled}
                  />
                </div>
                <div className="hidden sm:block flex justify-center sm:justify-normal sm:pb-2">
                  <ScreenMenu
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
                  {screen === "upgrade" && <UpgradeScreen upgrade={upgrade} />}
                  {screen === "profile" && <Profile />}
                  {screen === "encounters" && <EncountersScreen />}
                  {screen === "guide" && <GuideScreen />}
                  {screen === "settings" && <Settings />}
                  {screen === "player" && <Player />}
                  {screen === "wallet" && <WalletSelect />}
                </>
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
