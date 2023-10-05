"use client";
import {
  useAccount,
  useConnectors,
  useNetwork,
  useProvider,
  useTransactionManager,
} from "@starknet-react/core";
import { constants } from "starknet";
import { useState, useEffect, useMemo, useRef } from "react";
import ActionsScreen from "./containers/ActionsScreen";
import AdventurerScreen from "./containers/AdventurerScreen";
import InventoryScreen from "./containers/InventoryScreen";
import LeaderboardScreen from "./containers/LeaderboardScreen";
import EncountersScreen from "./containers/EncountersScreen";
import GuideScreen from "./containers/GuideScreen";
import UpgradeScreen from "./containers/UpgradeScreen";
import { padAddress } from "./lib/utils";
import Intro from "./components/intro/Intro";
import { TxActivity } from "./components/navigation/TxActivity";
import useLoadingStore from "./hooks/useLoadingStore";
import useAdventurerStore from "./hooks/useAdventurerStore";
import useUIStore from "./hooks/useUIStore";
import useTransactionCartStore from "./hooks/useTransactionCartStore";
import { NotificationDisplay } from "./components/notifications/NotificationDisplay";
import { useMusic } from "./hooks/useMusic";
import { Menu } from "./types";
import { useQueriesStore } from "./hooks/useQueryStore";
import Profile from "./containers/ProfileScreen";
import { DeathDialog } from "./components/adventurer/DeathDialog";
import WalletSelect from "./components/intro/WalletSelect";
import Settings from "./components/navigation/Settings";
import MobileHeader from "./components/navigation/MobileHeader";
import Player from "./components/adventurer/Player";
import { useUiSounds } from "./hooks/useUiSound";
import { soundSelector } from "./hooks/useUiSound";
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
import ScreenMenu from "./components/menu/ScreenMenu";
import Header from "./components/navigation/Header";

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
  const { chain } = useNetwork();
  const { provider } = useProvider();
  const disconnected = useUIStore((state) => state.disconnected);
  const setDisconnected = useUIStore((state) => state.setDisconnected);
  const { account, address, status, isConnected } = useAccount();
  const isMuted = useUIStore((state) => state.isMuted);
  const [introComplete, setIntroComplete] = useState(false);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const calls = useTransactionCartStore((state) => state.calls);
  const screen = useUIStore((state) => state.screen);
  const setScreen = useUIStore((state) => state.setScreen);
  const deathDialog = useUIStore((state) => state.deathDialog);
  const setMintAdventurer = useUIStore((state) => state.setMintAdventurer);
  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);
  const hasStatUpgrades = useAdventurerStore(
    (state) => state.computed.hasStatUpgrades
  );
  const owner = account?.address ? padAddress(account.address) : "";
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const setIsWrongNetwork = useUIStore((state) => state.setIsWrongNetwork);

  const arcadeDialog = useUIStore((state) => state.arcadeDialog);
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
  const setEquipItems = useUIStore((state) => state.setEquipItems);
  const setDropItems = useUIStore((state) => state.setDropItems);
  const setDeathMessage = useLoadingStore((state) => state.setDeathMessage);
  const showDeathDialog = useUIStore((state) => state.showDeathDialog);
  const setStartOption = useUIStore((state) => state.setStartOption);

  const lordsBalance = useBalance({
    token: lordsContract?.address,
    address,
  });

  const ethBalance = useBalance({
    token: ethContract?.address,
    address,
  });

  const { data, refetch, resetData, setData, setIsLoading, setNotLoading } =
    useQueriesStore();

  const { spawn, explore, attack, flee, upgrade, multicall } = syscalls({
    gameContract,
    lordsContract,
    addTransaction,
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
    setEquipItems,
    setDropItems,
    setDeathMessage,
    showDeathDialog,
    setScreen,
    setAdventurer,
    setMintAdventurer,
    setStartOption,
    ethBalance: ethBalance.data?.value ?? BigInt(0),
    showTopUpDialog,
    setTopUpAccount,
    setEstimatingFee,
    account,
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
            <Header multicall={multicall} />
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

          {status == "connected" && arcadeDialog && <ArcadeDialog />}
          {status == "connected" && topUpDialog && <TopUpDialog />}

          {introComplete ? (
            <div className="flex flex-col w-full h-[625px]">
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
                <div className="h-[600px]">
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
                </div>
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
