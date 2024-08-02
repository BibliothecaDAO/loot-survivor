"use client";
import { useConnect, useContract, useProvider } from "@starknet-react/core";
import { sepolia } from "@starknet-react/chains";
import { constants } from "starknet";
import { useState, useEffect, useMemo, useCallback, useRef } from "react";
import ActionsScreen from "@/app/containers/ActionsScreen";
import AdventurerScreen from "@/app/containers/AdventurerScreen";
import InventoryScreen from "@/app/containers/InventoryScreen";
import LeaderboardScreen from "@/app/containers/LeaderboardScreen";
import EncountersScreen from "@/app/containers/EncountersScreen";
import GuideScreen from "@/app/containers/GuideScreen";
import UpgradeScreen from "@/app/containers/UpgradeScreen";
import { indexAddress, padAddress } from "@/app/lib/utils";
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
import NetworkSwitchError from "@/app/components/navigation/NetworkSwitchError";
import { useSyscalls } from "@/app/lib/utils/syscalls";
import Game from "@/app/abi/Game.json";
import Lords from "@/app/abi/Lords.json";
import EthBalanceFragment from "@/app/abi/EthBalanceFragment.json";
import Beasts from "@/app/abi/Beasts.json";
import Pragma from "@/app/abi/Pragma.json";
import ScreenMenu from "@/app/components/menu/ScreenMenu";
import { checkArcadeConnector } from "@/app/lib/connectors";
import Header from "@/app/components/navigation/Header";
import { fetchBalances, fetchEthBalance } from "@/app/lib/balances";
import useTransactionManager from "@/app/hooks/useTransactionManager";
import { SpecialBeast } from "@/app/components/notifications/SpecialBeast";
import Storage from "@/app/lib/storage";
import Onboarding from "./containers/Onboarding";
import useControls from "@/app/hooks/useControls";
import { networkConfig } from "@/app/lib/networkConfig";
import useNetworkAccount from "@/app/hooks/useNetworkAccount";
import { useController } from "@/app/context/ControllerContext";
import EncounterTable from "@/app/components/encounters/EncounterTable";
import { ProfileDialog } from "@/app/components/profile/ProfileDialog";
import TokenLoader from "@/app/components/animations/TokenLoader";
import CartridgeConnector from "@cartridge/connector";
import { VRF_WAIT_TIME } from "@/app/lib/constants";
import { GameData } from "@/app/lib/data/GameData";
import InterludeScreen from "@/app/containers/InterludeScreen";

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
  return (
    <main
      className={`min-h-screen container mx-auto flex flex-col sm:pt-8 sm:p-8 lg:p-10 2xl:p-20 `}
    >
      <Home />
    </main>
  );
}

function Home() {
  const { connector } = useConnect();
  const network = useUIStore((state) => state.network);
  const onKatana = useUIStore((state) => state.onKatana);
  const { account, address, isConnected } = useNetworkAccount();
  const { provider } = useProvider();
  const isMuted = useUIStore((state) => state.isMuted);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const calls = useTransactionCartStore((state) => state.calls);
  const screen = useUIStore((state) => state.screen);
  const setScreen = useUIStore((state) => state.setScreen);
  const deathDialog = useUIStore((state) => state.deathDialog);
  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);
  const hasStatUpgrades = useAdventurerStore(
    (state) => state.computed.hasStatUpgrades
  );
  const owner = account?.address ? padAddress(account.address) : "";
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const setIsWrongNetwork = useUIStore((state) => state.setIsWrongNetwork);
  const showTopUpDialog = useUIStore((state) => state.showTopUpDialog);
  const setTopUpAccount = useUIStore((state) => state.setTopUpAccount);
  const setSpecialBeast = useUIStore((state) => state.setSpecialBeast);
  const isMintingLords = useUIStore((state) => state.isMintingLords);
  const isWithdrawing = useUIStore((state) => state.isWithdrawing);
  const setIsMintingLords = useUIStore((state) => state.setIsMintingLords);
  const setIsWithdrawing = useUIStore((state) => state.setIsWithdrawing);
  const hash = useLoadingStore((state) => state.hash);
  const specialBeastDefeated = useUIStore(
    (state) => state.specialBeastDefeated
  );
  const onboarded = useUIStore((state) => state.onboarded);
  const setSpecialBeastDefeated = useUIStore(
    (state) => state.setSpecialBeastDefeated
  );
  const encounterTable = useUIStore((state) => state.encounterTable);
  const setAdventurerEntropy = useUIStore(
    (state) => state.setAdventurerEntropy
  );
  const showProfile = useUIStore((state) => state.showProfile);
  const itemEntropy = useUIStore((state) => state.itemEntropy);
  const setItemEntropy = useUIStore((state) => state.setItemEntropy);

  const { contract: gameContract } = useContract({
    address: networkConfig[network!].gameAddress,
    abi: Game,
  });
  const { contract: lordsContract } = useContract({
    address: networkConfig[network!].lordsAddress,
    abi: Lords,
  });
  const { contract: ethContract } = useContract({
    address: networkConfig[network!].ethAddress,
    abi: EthBalanceFragment,
  });
  const { contract: beastsContract } = useContract({
    address: networkConfig[network!].beastsAddress,
    abi: Beasts,
  });
  const { contract: pragmaContract } = useContract({
    address: networkConfig[network!].pragmaAddress,
    abi: Pragma,
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
  const entropyReady = useUIStore((state) => state.entropyReady);
  const setEntropyReady = useUIStore((state) => state.setEntropyReady);
  const fetchUnlocksEntropy = useUIStore((state) => state.fetchUnlocksEntropy);
  const setFetchUnlocksEntropy = useUIStore(
    (state) => state.setFetchUnlocksEntropy
  );
  const adventurerEntropy = useUIStore((state) => state.adventurerEntropy);
  const [accountChainId, setAccountChainId] = useState<
    constants.StarknetChainId | undefined
  >();
  const setUsername = useUIStore((state) => state.setUsername);
  const setIsController = useUIStore((state) => state.setIsController);
  const setControllerAdmin = useUIStore((state) => state.setControllerAdmin);

  useEffect(() => {
    const init = async () => {
      const username = await (
        connector as unknown as CartridgeConnector
      ).username();
      const delegateAccount = await (
        connector as unknown as CartridgeConnector
      ).delegateAccount();
      setUsername(username || "");
      setControllerAdmin(delegateAccount!.toString() || "");
    };
    if (connector?.id.includes("cartridge")) {
      setIsController(true);
      init();
    } else {
      setIsController(false);
      setControllerAdmin("");
      setUsername("");
    }
  }, [connector]);

  const gameData = new GameData();

  const ethBalanceRef = useRef(BigInt(0));
  const lordsBalanceRef = useRef(BigInt(0));

  const getBalances = useCallback(async () => {
    const balances = await fetchBalances(
      address ?? "0x0",
      ethContract,
      lordsContract,
      gameContract
    );
    ethBalanceRef.current = balances[0];
    lordsBalanceRef.current = balances[1];
  }, [address, ethContract, lordsContract, gameContract]);

  const getEthBalance = async () => {
    const ethBalance = await fetchEthBalance(address ?? "0x0", ethContract);
    ethBalanceRef.current = ethBalance;
  };

  useEffect(() => {
    if (!onKatana) {
      getBalances();
    }
  }, [account]);

  const { data, refetch, resetData, setData, setIsLoading, setNotLoading } =
    useQueriesStore();

  const {
    spawn,
    explore,
    attack,
    flee,
    upgrade,
    multicall,
    mintLords,
    withdraw,
  } = useSyscalls({
    gameContract: gameContract!,
    ethContract: ethContract!,
    lordsContract: lordsContract!,
    beastsContract: beastsContract!,
    pragmaContract: pragmaContract!,
    rendererContractAddress: networkConfig[network!].rendererAddress,
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
    ethBalance: ethBalanceRef.current,
    showTopUpDialog,
    setTopUpAccount,
    account: account!,
    setSpecialBeastDefeated,
    setSpecialBeast,
    connector,
    getEthBalance,
    getBalances,
    setIsMintingLords,
    setIsWithdrawing,
    setEntropyReady,
    setFetchUnlocksEntropy,
    provider,
    network,
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

  const ownerVariables = useMemo(() => {
    return {
      owner: indexAddress(owner),
    };
  }, [owner]);

  const adventurersData = useCustomQuery(
    network,
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

  useCustomQuery(
    network,
    "adventurerByIdQuery",
    getAdventurerById,
    adventurerVariables
  );

  useCustomQuery(
    network,
    "latestDiscoveriesQuery",
    getLatestDiscoveries,
    adventurerVariables
  );

  useCustomQuery(
    network,
    "itemsByAdventurerQuery",
    getItemsByAdventurer,
    adventurerVariables
  );

  useCustomQuery(
    network,
    "latestMarketItemsQuery",
    getLatestMarketItems,
    adventurerVariables
  );

  const lastBeastData = useCustomQuery(
    network,
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

  useCustomQuery(network, "beastQuery", getBeast, beastVariables);

  useCustomQuery(
    network,
    "battlesByBeastQuery",
    getBattlesByBeast,
    beastVariables
  );

  const goldenTokenVariables = useMemo(() => {
    const storage: BurnerStorage = Storage.get("burners");
    const isArcade = checkArcadeConnector(connector);
    if (isArcade && address) {
      const masterAccount = storage[address].masterAccount;
      return {
        contractAddress:
          networkConfig[network!].goldenTokenAddress.toLowerCase(),
        owner: padAddress(masterAccount ?? ""),
      };
    } else {
      return {
        contractAddress:
          networkConfig[network!].goldenTokenAddress.toLowerCase(),
        owner: padAddress(address ?? ""),
      };
    }
  }, [address]);

  const goldenTokenClientInstance = useMemo(
    () => goldenTokenClient(networkConfig[network!].tokensGQLURL),
    [network]
  );

  const { data: goldenTokenData } = useQuery(getGoldenTokensByOwner, {
    client: goldenTokenClientInstance,
    variables: goldenTokenVariables,
  });

  const handleSwitchAdventurer = useCallback(
    async (adventurerId: number) => {
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
    },
    [owner, adventurer?.id]
  );

  useEffect(() => {
    return () => {
      stop();
    };
  }, [play, stop]);

  const mobileMenuDisabled = useMemo(
    () => [false, hasStatUpgrades, false, !hasStatUpgrades, false, false],
    [hasStatUpgrades]
  );

  const allMenuDisabled = useMemo(
    () => [
      false,
      hasStatUpgrades,
      false,
      !hasStatUpgrades,
      false,
      false,
      false,
    ],
    [hasStatUpgrades]
  );

  const adventurers = adventurersData?.adventurers;

  useEffect(() => {
    if (adventurers && adventurers.length > 0) {
      const latestAdventurer: Adventurer = adventurers[adventurers.length - 1];
      if (latestAdventurer.health !== 0) {
        setAdventurer(latestAdventurer);
        handleSwitchAdventurer(latestAdventurer.id!);
      }
    }
  }, [adventurers]);

  useEffect(() => {
    if (adventurer?.id && adventurer.health !== 0) {
      if (!hasStatUpgrades) {
        setScreen("play");
      } else {
        setScreen("upgrade");
      }
    }
  }, [adventurer]);

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
      (network === "mainnet"
        ? constants.StarknetChainId.SN_MAIN
        : network === "sepolia"
        ? "0x" + sepolia.id.toString(16)
        : "0x4b4154414e41"); // katana chain ID
    setIsWrongNetwork(isWrongNetwork);
  }, [account, accountChainId, isConnected]);

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

  const [costToPlay, setCostToPlay] = useState<bigint>(BigInt(0));

  useEffect(() => {
    const getCostToPlay = async () => {
      if (gameContract) {
        const result = await gameContract.call("get_cost_to_play", []);
        setCostToPlay(result as bigint);
      }
    };
    getCostToPlay();
  }, [gameContract]);

  const { setCondition } = useController();
  useControls();

  useEffect(() => {
    setCondition("a", screen === "play" && hasBeast);
    setCondition("s", screen === "play" && hasBeast);
    setCondition("f", screen === "play" && hasBeast);
    setCondition("g", screen === "play" && hasBeast);
    setCondition("e", screen === "play" && !hasBeast);
    setCondition("r", screen === "play" && !hasBeast);
    setCondition("u", screen === "upgrade");
    setCondition(
      "i",
      screen === "play" ||
        screen === "beast" ||
        screen === "upgrade" ||
        screen === "inventory"
    );
  }, [screen, hasBeast]);

  useEffect(() => {
    if (!onboarded) {
      setScreen("onboarding");
    } else if (onboarded) {
      setScreen("start");
    }
  }, [onboarded]);

  useEffect(() => {
    const fetchEntropy = async () => {
      if (adventurer?.id) {
        const adventurerMeta: any = await gameContract!.call(
          "get_adventurer_meta",
          [adventurer?.id!]
        );
        const entropy = adventurerMeta.level_seed;
        if (entropy !== BigInt(0)) {
          setAdventurerEntropy(BigInt(entropy.toString()));
          setEntropyReady(true);
          clearInterval(interval);
        }
      }
    };

    // Call the function immediately
    fetchEntropy();

    // Set up the interval to call the function every 5 seconds
    const interval = setInterval(fetchEntropy, VRF_WAIT_TIME);

    return () => clearInterval(interval); // Cleanup on component unmount
  }, [adventurer?.level]);

  const fetchItemSpecials = async () => {
    if (entropyReady || onKatana) {
      const marketItems = (await gameContract!.call("get_market", [
        adventurer?.id!,
      ])) as string[];
      const itemData = [];
      for (let item of marketItems) {
        itemData.unshift({
          item: gameData.ITEMS[parseInt(item)],
          adventurerId: adventurer?.id,
          owner: false,
          equipped: false,
          ownerAddress: adventurer?.owner,
          xp: 0,
          special1: null,
          special2: null,
          special3: null,
          isAvailable: false,
          purchasedTime: null,
          timestamp: new Date(),
        });
      }
      setData("latestMarketItemsQuery", {
        items: itemData,
      });
    }
  };

  useEffect(() => {
    const fetchEntropy = async () => {
      if (adventurer?.id && fetchUnlocksEntropy) {
        const entropy = await gameContract!.call("get_item_entropy", [
          adventurer?.id!,
        ]);
        if (entropy !== BigInt(0)) {
          setFetchUnlocksEntropy(false);
          setItemEntropy(BigInt(entropy.toString()));
          fetchItemSpecials();
          clearInterval(interval);
        }
      }
    };

    // Call the function immediately
    if (itemEntropy === BigInt(0)) {
      fetchEntropy();
    }

    // Set up the interval to call the function every 5 seconds
    const interval = setInterval(fetchEntropy, VRF_WAIT_TIME);

    return () => clearInterval(interval); // Cleanup on component unmount
  }, [fetchUnlocksEntropy]);

  return (
    <>
      {((!entropyReady && hasStatUpgrades) || fetchUnlocksEntropy) &&
        !onKatana && (
          <InterludeScreen type={fetchUnlocksEntropy ? "item" : "level"} />
        )}
      <NetworkSwitchError network={network} isWrongNetwork={isWrongNetwork} />
      {isMintingLords && <TokenLoader isToppingUpLords={isMintingLords} />}
      {isWithdrawing && <TokenLoader isWithdrawing={isWithdrawing} />}
      {screen === "onboarding" ? (
        <Onboarding
          ethBalance={ethBalanceRef.current}
          lordsBalance={lordsBalanceRef.current}
          costToPlay={costToPlay}
          mintLords={mintLords}
          getBalances={getBalances}
        />
      ) : (
        <>
          <div className="flex flex-col w-full">
            {specialBeastDefeated && (
              <SpecialBeast beastsContract={beastsContract!} />
            )}
            {!spawnLoader && hash && (
              <div className="sm:hidden">
                <TxActivity />
              </div>
            )}
            <Header
              multicall={multicall}
              mintLords={mintLords}
              ethBalance={ethBalanceRef.current}
              lordsBalance={lordsBalanceRef.current}
              gameContract={gameContract!}
              costToPlay={costToPlay}
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
          <div className="flex flex-col w-full h-[600px] sm:h-[625px]">
            <>
              <div className="sm:hidden flex  sm:justify-normal sm:pb-2">
                <ScreenMenu
                  buttonsData={mobileMenuItems}
                  onButtonClick={(value) => {
                    setScreen(value);
                  }}
                  disabled={mobileMenuDisabled}
                  hideEncounters={
                    adventurerEntropy === BigInt(0) || !adventurer?.id
                  }
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
                    lordsBalance={lordsBalanceRef.current}
                    gameContract={gameContract!}
                    goldenTokenData={goldenTokenData}
                    getBalances={getBalances}
                    mintLords={mintLords}
                    costToPlay={costToPlay}
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
                {screen === "leaderboard" && <LeaderboardScreen />}
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
                {screen === "player" && <Player gameContract={gameContract!} />}
                {screen === "wallet" && <WalletSelect />}

                {encounterTable && (
                  <div className="absolute top-0 right-0 sm:right-32 sm:top-32">
                    <EncounterTable />
                  </div>
                )}

                {showProfile && (
                  <div className="absolute flex items-center justify-center top-0 right-0 left-0 w-full h-full bg-black/50">
                    <span className="w-full h-full bg-black/50" />
                    <ProfileDialog
                      withdraw={withdraw}
                      ethBalance={ethBalanceRef.current}
                      lordsBalance={lordsBalanceRef.current}
                      ethContractAddress={ethContract!.address}
                      lordsContractAddress={lordsContract!.address}
                    />
                  </div>
                )}
              </div>
            </>
          </div>
        </>
      )}
    </>
  );
}
