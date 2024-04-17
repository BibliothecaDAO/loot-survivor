"use client";
import {
  useAccount,
  useConnect,
  useContract,
  Connector,
} from "@starknet-react/core";
import { sepolia } from "@starknet-react/chains";
import { InjectedConnector } from "starknetkit/injected";
import { ArgentMobileConnector } from "starknetkit/argentMobile";
import { WebWalletConnector } from "starknetkit/webwallet";
import { constants } from "starknet";
import { useState, useEffect, useMemo } from "react";
import ActionsScreen from "@/app/containers/ActionsScreen";
import AdventurerScreen from "@/app/containers/AdventurerScreen";
import InventoryScreen from "@/app/containers/InventoryScreen";
import LeaderboardScreen from "@/app/containers/LeaderboardScreen";
import EncountersScreen from "@/app/containers/EncountersScreen";
import GuideScreen from "@/app/containers/GuideScreen";
import UpgradeScreen from "@/app/containers/UpgradeScreen";
import { padAddress } from "@/app/lib/utils";
import Intro from "@/app/components/intro/Intro";
import { TxActivity } from "@/app/components/navigation/TxActivity";
import useLoadingStore from "@/app/hooks/useLoadingStore";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import useUIStore from "@/app/hooks/useUIStore";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import { NotificationDisplay } from "@/app/components/notifications/NotificationDisplay";
import { useMusic } from "@/app/hooks/useMusic";
import { Menu, ZeroUpgrade, BurnerStorage, Adventurer } from "@/app/types";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import Profile from "@/app/containers/ProfileScreen";
import { DeathDialog } from "@/app/components/adventurer/DeathDialog";
import WalletSelect from "@/app/components/intro/WalletSelect";
import Settings from "@/app/components/navigation/Settings";
import MobileHeader from "@/app/components/navigation/MobileHeader";
import Player from "@/app/components/adventurer/Player";
import useCustomQuery from "@/app/hooks/useCustomQuery";
import { useQuery } from "@apollo/client";
import { goldenTokenClient } from "@/app/lib/clients";
import {
  getAdventurerById,
  getAdventurersByOwner,
  getLatestDiscoveries,
  getLastBeastDiscovery,
  getBeast,
  getBattlesByBeast,
  getItemsByAdventurer,
  getLatestMarketItems,
  getGoldenTokensByOwner,
} from "@/app/hooks/graphql/queries";
import { ArcadeDialog } from "@/app/components/ArcadeDialog";
import NetworkSwitchError from "@/app/components/navigation/NetworkSwitchError";
import { syscalls } from "@/app/lib/utils/syscalls";
import Game from "@/app/abi/Game.json";
import Lords from "@/app/abi/Lords.json";
import EthBalanceFragment from "@/app/abi/EthBalanceFragment.json";
import Beasts from "@/app/abi/Beasts.json";
import ScreenMenu from "@/app/components/menu/ScreenMenu";
import {
  getArcadeConnectors,
  checkArcadeConnector,
} from "@/app/lib/connectors";
import Header from "@/app/components/navigation/Header";
import { fetchBalances, fetchEthBalance } from "@/app/lib/balances";
import useTransactionManager from "@/app/hooks/useTransactionManager";
import { StarknetProvider } from "@/app//provider";
import { SpecialBeast } from "@/app/components/notifications/SpecialBeast";
import { useBurner } from "@/app/lib/burner";
import { connectors } from "@/app/lib/connectors";
import Storage from "@/app/lib/storage";
import Onboarding from "./containers/Onboarding";
import TopUp from "./containers/TopUp";

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

export default function Main() {
  const [appConnectors, setAppConnectors] = useState<
    (
      | Connector
      | WebWalletConnector
      | InjectedConnector
      | ArgentMobileConnector
    )[]
  >([]);

  const { listConnectors } = useBurner({});

  const updateConnectors = () => {
    const arcadeConnectors = listConnectors();
    setAppConnectors([...arcadeConnectors, ...connectors]);
  };

  useEffect(() => {
    updateConnectors();
  }, []);
  return (
    <StarknetProvider connectors={appConnectors}>
      <Home updateConnectors={updateConnectors} />
    </StarknetProvider>
  );
}

interface HomeProps {
  updateConnectors: () => void;
}

function Home({ updateConnectors }: HomeProps) {
  const { connect, connector, connectors } = useConnect();
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
  const handleOnboarded = useUIStore((state) => state.handleOnboarded);
  const deathDialog = useUIStore((state) => state.deathDialog);
  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);
  const hasStatUpgrades = useAdventurerStore(
    (state) => state.computed.hasStatUpgrades
  );
  const owner = account?.address ? padAddress(account.address) : "";
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const setIsWrongNetwork = useUIStore((state) => state.setIsWrongNetwork);
  const arcadeDialog = useUIStore((state) => state.arcadeDialog);
  const onboarded = useUIStore((state) => state.onboarded);
  const topUpDialog = useUIStore((state) => state.topUpDialog);
  const showTopUpDialog = useUIStore((state) => state.showTopUpDialog);
  const setTopUpAccount = useUIStore((state) => state.setTopUpAccount);
  const setEstimatingFee = useUIStore((state) => state.setEstimatingFee);
  const setSpecialBeast = useUIStore((state) => state.setSpecialBeast);
  const setIsMintingLords = useUIStore((state) => state.setIsMintingLords);
  const hash = useLoadingStore((state) => state.hash);
  const specialBeastDefeated = useUIStore(
    (state) => state.specialBeastDefeated
  );
  const setSpecialBeastDefeated = useUIStore(
    (state) => state.setSpecialBeastDefeated
  );
  const { contract: gameContract } = useContract({
    address: process.env.NEXT_PUBLIC_GAME_ADDRESS,
    abi: Game,
  });
  const { contract: lordsContract } = useContract({
    address: process.env.NEXT_PUBLIC_LORDS_ADDRESS,
    abi: Lords,
  });
  const { contract: ethContract } = useContract({
    address: process.env.NEXT_PUBLIC_ETH_ADDRESS,
    abi: EthBalanceFragment,
  });
  const { contract: beastsContract } = useContract({
    address: process.env.NEXT_PUBLIC_BEASTS_ADDRESS,
    abi: Beasts,
  });

  const { addTransaction } = useTransactionManager();
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const resetCalls = useTransactionCartStore((state) => state.resetCalls);
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const startLoading = useLoadingStore((state) => state.startLoading);
  const stopLoading = useLoadingStore((state) => state.stopLoading);
  const pendingMessage = useLoadingStore((state) => state.pendingMessage);
  const setTxHash = useLoadingStore((state) => state.setTxHash);
  const setEquipItems = useUIStore((state) => state.setEquipItems);
  const setDropItems = useUIStore((state) => state.setDropItems);
  const setPotionAmount = useUIStore((state) => state.setPotionAmount);
  const setUpgrades = useUIStore((state) => state.setUpgrades);
  const setPurchaseItems = useUIStore((state) => state.setPurchaseItems);
  const setDeathMessage = useLoadingStore((state) => state.setDeathMessage);
  const showDeathDialog = useUIStore((state) => state.showDeathDialog);
  const setStartOption = useUIStore((state) => state.setStartOption);
  const setUpdateDeathPenalty = useUIStore(
    (state) => state.setUpdateDeathPenalty
  );
  const [accountChainId, setAccountChainId] = useState<
    constants.StarknetChainId | undefined
  >();

  const arcadeConnectors = getArcadeConnectors(connectors);

  const [ethBalance, setEthBalance] = useState<bigint>(BigInt(0));
  const [lordsBalance, setLordsBalance] = useState<bigint>(BigInt(0));
  const [costToPlay, setCostToPlay] = useState<bigint | undefined>();

  const getBalances = async () => {
    const balances = await fetchBalances(
      address ?? "0x0",
      ethContract,
      lordsContract,
      gameContract
    );
    setEthBalance(balances[0]);
    setLordsBalance(balances[1]);
  };

  const getEthBalance = async () => {
    const ethBalance = await fetchEthBalance(address ?? "0x0", ethContract);
    setEthBalance(ethBalance);
  };

  useEffect(() => {
    getBalances();
  }, [account]);

  const { data, refetch, resetData, setData, setIsLoading, setNotLoading } =
    useQueriesStore();

  const {
    spawn,
    explore,
    attack,
    flee,
    upgrade,
    slayIdles,
    multicall,
    mintLords,
    suicide,
  } = syscalls({
    gameContract: gameContract!,
    lordsContract: lordsContract!,
    beastsContract: beastsContract!,
    addTransaction,
    queryData: data,
    resetData,
    setData,
    adventurer: adventurer!,
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
    setStartOption,
    ethBalance: ethBalance,
    showTopUpDialog,
    setTopUpAccount,
    setEstimatingFee,
    account: account!,
    resetCalls,
    setSpecialBeastDefeated,
    setSpecialBeast,
    connector,
    getEthBalance,
    getBalances,
    setIsMintingLords,
    setUpdateDeathPenalty,
  });

  const playState = useMemo(
    () => ({
      isInBattle: hasBeast,
      isDead: deathDialog, // set this to true when player is dead
      isMuted: isMuted,
    }),
    [hasBeast, deathDialog, isMuted]
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

  const goldenTokenVariables = useMemo(() => {
    const storage: BurnerStorage = Storage.get("burners");
    const isArcade = checkArcadeConnector(connector);
    if (isArcade && address) {
      const masterAccount = storage[address].masterAccount;
      return {
        contractAddress:
          process.env.NEXT_PUBLIC_GOLDEN_TOKEN_ADDRESS?.toLowerCase(),
        owner: padAddress(masterAccount ?? ""),
      };
    } else {
      return {
        contractAddress:
          process.env.NEXT_PUBLIC_GOLDEN_TOKEN_ADDRESS?.toLowerCase(),
        owner: padAddress(address ?? ""),
      };
    }
  }, [address]);

  const { data: goldenTokenData } = useQuery(getGoldenTokensByOwner, {
    client: goldenTokenClient,
    variables: goldenTokenVariables,
  });

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

  const adventurers = adventurersData?.adventurers;

  useEffect(() => {
    if (!address && arcadeConnectors.length > 0) {
      connect({ connector: arcadeConnectors[0] });
    }
  }, [screen]);

  useEffect(() => {
    if (adventurers && adventurers.length > 0) {
      const latestAdventurer: Adventurer = adventurers[adventurers.length - 1];
      if (latestAdventurer.health !== 0) {
        setAdventurer(latestAdventurer);
        handleSwitchAdventurer(latestAdventurer.id!);
      }
    }
  }, [introComplete, adventurers]);

  useEffect(() => {
    if (adventurer?.id && adventurer.health !== 0) {
      if (!hasStatUpgrades) {
        setScreen("play");
      } else {
        setScreen("upgrade");
      }
    }
  }, [introComplete, adventurer]);

  const getAccountChainId = async () => {
    if (account) {
      const chainId = await account!.getChainId();
      setAccountChainId(chainId);
    }
  };

  useEffect(() => {
    getAccountChainId();
    const isWrongNetwork =
      accountChainId !==
      (process.env.NEXT_PUBLIC_NETWORK === "mainnet"
        ? constants.StarknetChainId.SN_MAIN
        : process.env.NEXT_PUBLIC_NETWORK === "sepolia"
        ? "0x" + sepolia.id.toString(16)
        : constants.StarknetChainId.SN_GOERLI);
    setIsWrongNetwork(isWrongNetwork);
  }, [account, accountChainId, isConnected]);

  useEffect(() => {
    if (arcadeConnectors.length === 0 && !onboarded) {
      setScreen("onboarding");
    } else if (!onboarded) {
      handleOnboarded();
      setScreen("start");
    }
  }, [arcadeConnectors]);

  useEffect(() => {
    resetCalls();
    setDropItems([]);
    setEquipItems([]);
    setPotionAmount(0);
    setPurchaseItems([]);
    setUpgrades({ ...ZeroUpgrade });
  }, [adventurer]);

  const spawnLoader =
    pendingMessage &&
    (pendingMessage === "Spawning Adventurer" ||
      pendingMessage.includes("Spawning Adventurer"));

  const getCostToPlay = async () => {
    const cost = await gameContract!.call("get_cost_to_play", []);
    setCostToPlay(cost as bigint);
  };

  useEffect(() => {
    getCostToPlay();
  }, []);

  if (!isConnected && introComplete && disconnected) {
    return <WalletSelect />;
  }

  return (
    <main
      className={`min-h-screen container mx-auto flex flex-col sm:pt-8 sm:p-8 lg:p-10 2xl:p-20 `}
    >
      {introComplete ? (
        <>
          <NetworkSwitchError isWrongNetwork={isWrongNetwork} />
          {screen === "onboarding" ? (
            <Onboarding
              ethBalance={ethBalance}
              lordsBalance={lordsBalance}
              costToPlay={costToPlay!}
              mintLords={mintLords}
              gameContract={gameContract!}
              lordsContract={lordsContract!}
              ethContract={ethContract!}
              updateConnectors={updateConnectors}
            />
          ) : status == "connected" && topUpDialog ? (
            <TopUp
              ethBalance={ethBalance}
              lordsBalance={lordsBalance}
              costToPlay={costToPlay!}
              mintLords={mintLords}
              gameContract={gameContract!}
              lordsContract={lordsContract!}
              ethContract={ethContract!}
              updateConnectors={updateConnectors}
              showTopUpDialog={showTopUpDialog}
            />
          ) : (
            <>
              <div className="flex flex-col w-full">
                {specialBeastDefeated && <SpecialBeast />}
                {!spawnLoader && hash && (
                  <div className="sm:hidden">
                    <TxActivity />
                  </div>
                )}
                <Header
                  multicall={multicall}
                  mintLords={mintLords}
                  suicide={suicide}
                  lordsBalance={lordsBalance}
                  gameContract={gameContract!}
                  costToPlay={costToPlay!}
                />
              </div>
              <div className="w-full h-1 sm:h-6 sm:my-2 bg-terminal-green text-terminal-black px-4">
                {!spawnLoader && hash && (
                  <div className="hidden sm:block">
                    <TxActivity />
                  </div>
                )}
              </div>
              <NotificationDisplay />

              {deathDialog && <DeathDialog />}
              {status == "connected" && arcadeDialog && (
                <ArcadeDialog
                  gameContract={gameContract!}
                  lordsContract={lordsContract!}
                  ethContract={ethContract!}
                  updateConnectors={updateConnectors}
                  lordsBalance={Number(lordsBalance)}
                  ethBalance={Number(ethBalance)}
                  costToPlay={costToPlay!}
                  getAccountBalances={getBalances}
                />
              )}
              {introComplete ? (
                <div className="flex flex-col w-full h-[600px] sm:h-[625px]">
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
                    <div className="h-[550px] xl:h-[500px] 2xl:h-[580px]">
                      {screen === "start" && (
                        <AdventurerScreen
                          spawn={spawn}
                          handleSwitchAdventurer={handleSwitchAdventurer}
                          lordsBalance={lordsBalance}
                          gameContract={gameContract!}
                          goldenTokenData={goldenTokenData}
                          getBalances={getBalances}
                          mintLords={mintLords}
                          costToPlay={costToPlay!}
                        />
                      )}
                      {screen === "play" && (
                        <ActionsScreen
                          explore={explore}
                          attack={attack}
                          flee={flee}
                          gameContract={gameContract!}
                          beastsContract={beastsContract!}
                        />
                      )}
                      {screen === "inventory" && (
                        <InventoryScreen gameContract={gameContract!} />
                      )}
                      {screen === "leaderboard" && (
                        <LeaderboardScreen
                          slayIdles={slayIdles}
                          gameContract={gameContract!}
                        />
                      )}
                      {screen === "upgrade" && (
                        <UpgradeScreen
                          upgrade={upgrade}
                          gameContract={gameContract!}
                        />
                      )}
                      {screen === "profile" && (
                        <Profile gameContract={gameContract!} />
                      )}
                      {screen === "encounters" && <EncountersScreen />}
                      {screen === "guide" && <GuideScreen />}
                      {screen === "settings" && <Settings />}
                      {screen === "player" && (
                        <Player gameContract={gameContract!} />
                      )}
                      {screen === "wallet" && <WalletSelect />}
                    </div>
                  </>
                </div>
              ) : null}
            </>
          )}
        </>
      ) : (
        <Intro onIntroComplete={handleIntroComplete} />
      )}
    </main>
  );
}
