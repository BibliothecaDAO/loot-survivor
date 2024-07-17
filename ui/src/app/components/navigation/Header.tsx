import { useCallback, useRef, useState, useEffect } from "react";
import { Contract } from "starknet";
import { useDisconnect, useConnect } from "@starknet-react/core";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import useUIStore from "@/app/hooks/useUIStore";
import { useUiSounds, soundSelector } from "@/app/hooks/useUiSound";
import Logo from "public/icons/logo.svg";
import Eth from "public/icons/eth.svg";
import Lords from "public/icons/lords.svg";
import { Button } from "@/app/components/buttons/Button";
import {
  formatNumber,
  displayAddress,
  indexAddress,
  processItemName,
  getItemData,
  getItemPrice,
} from "@/app/lib/utils";
import {
  SoundOffIcon,
  SoundOnIcon,
  CartIcon,
  SettingsIcon,
  GithubIcon,
} from "@/app/components/icons/Icons";
import TransactionCart from "@/app/components/navigation/TransactionCart";
import TransactionHistory from "@/app/components/navigation/TransactionHistory";
import {
  NullAdventurer,
  Item,
  NullItem,
  UpgradeStats,
  ZeroUpgrade,
  Call,
} from "@/app/types";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import { getApibaraStatus } from "@/app/api/api";
import ApibaraStatus from "@/app/components/navigation/ApibaraStatus";
import TokenLoader from "@/app/components/animations/TokenLoader";
import { checkCartridgeConnector } from "@/app/lib/connectors";
import { networkConfig } from "@/app/lib/networkConfig";
import useNetworkAccount from "@/app/hooks/useNetworkAccount";
import useLoadingStore from "@/app/hooks/useLoadingStore";
import { useController } from "@/app/context/ControllerContext";
import { vitalityIncrease } from "@/app/lib/constants";

export interface HeaderProps {
  multicall: (
    loadingMessage: string[],
    notification: string[],
    upgradeTx?: any
  ) => Promise<void>;
  mintLords: (lordsAmount: number) => Promise<void>;
  ethBalance: bigint;
  lordsBalance: bigint;
  gameContract: Contract;
  costToPlay: bigint;
}

export default function Header({
  multicall,
  mintLords,
  ethBalance,
  lordsBalance,
  gameContract,
  costToPlay,
}: HeaderProps) {
  const [mintingLords, setMintingLords] = useState(false);
  const { account } = useNetworkAccount();
  const { connector } = useConnect();
  const { disconnect } = useDisconnect();
  const [apibaraStatus, setApibaraStatus] = useState();
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const resetData = useQueriesStore((state) => state.resetData);

  const setDisconnected = useUIStore((state) => state.setDisconnected);
  const isMuted = useUIStore((state) => state.isMuted);
  const setIsMuted = useUIStore((state) => state.setIsMuted);
  const displayCart = useUIStore((state) => state.displayCart);
  const setDisplayCart = useUIStore((state) => state.setDisplayCart);
  const displayHistory = useUIStore((state) => state.displayHistory);
  const setDisplayHistory = useUIStore((state) => state.setDisplayHistory);
  const setScreen = useUIStore((state) => state.setScreen);
  const network = useUIStore((state) => state.network);
  const setNetwork = useUIStore((state) => state.setNetwork);
  const onMainnet = useUIStore((state) => state.onMainnet);
  const onKatana = useUIStore((state) => state.onKatana);
  const vitBoostRemoved = useUIStore((state) => state.vitBoostRemoved);
  const handleOffboarded = useUIStore((state) => state.handleOffboarded);
  const setLoginScreen = useUIStore((state) => state.setLoginScreen);

  const calls = useTransactionCartStore((state) => state.calls);
  const txInCart = calls.length > 0;

  const { play: clickPlay } = useUiSounds(soundSelector.click);

  const displayCartButtonRef = useRef<HTMLButtonElement>(null);
  const displayHistoryButtonRef = useRef<HTMLButtonElement>(null);

  const [showLordsBuy, setShowLordsBuy] = useState(false);

  const lordsGameCost = Number(costToPlay);

  const handleApibaraStatus = async () => {
    const data = await getApibaraStatus();
    setApibaraStatus(data.status.indicator);
  };

  const checkCartridge = checkCartridgeConnector(connector);

  useEffect(() => {
    handleApibaraStatus();
  }, []);

  const [notification, setNotification] = useState<any[]>([]);
  const [loadingMessage, setLoadingMessage] = useState<string[]>([]);
  const notificationData = useLoadingStore((state) => state.notificationData);
  const resetNotification = useLoadingStore((state) => state.resetNotification);
  const purchaseItems = useUIStore((state) => state.purchaseItems);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const data = useQueriesStore((state) => state.data);
  const potionAmount = useUIStore((state) => state.potionAmount);
  const upgrades = useUIStore((state) => state.upgrades);
  const selectedVitality = upgrades["Vitality"] ?? 0;
  const totalVitality = (adventurer?.vitality ?? 0) + selectedVitality;
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const removeEntrypointFromCalls = useTransactionCartStore(
    (state) => state.removeEntrypointFromCalls
  );
  const resetCalls = useTransactionCartStore((state) => state.resetCalls);
  const equipItems = useUIStore((state) => state.equipItems);
  const setEquipItems = useUIStore((state) => state.setEquipItems);
  const dropItems = useUIStore((state) => state.dropItems);
  const setDropItems = useUIStore((state) => state.setDropItems);
  const setPotionAmount = useUIStore((state) => state.setPotionAmount);
  const setPurchaseItems = useUIStore((state) => state.setPurchaseItems);
  const setUpgrades = useUIStore((state) => state.setUpgrades);
  const setUpgradeScreen = useUIStore((state) => state.setUpgradeScreen);
  const setSlayAdventurers = useUIStore((state) => state.setSlayAdventurers);
  const encounterTable = useUIStore((state) => state.encounterTable);
  const showEncounterTable = useUIStore((state) => state.showEncounterTable);

  const items = data.latestMarketItemsQuery
    ? data.latestMarketItemsQuery.items
    : [];

  const handleBuyItem = useCallback(
    (call: any) => {
      const item = items.find(
        (item: Item) =>
          item.item === (Array.isArray(call.calldata) && call.calldata[0])
      );
      const itemName = processItemName(item ?? NullItem);
      const { tier } = getItemData(item?.item ?? "");
      setNotification((notifications) => [
        ...notifications,
        `You purchased ${item?.item && itemName} for ${getItemPrice(
          tier,
          adventurer?.charisma ?? 0
        )} gold`,
      ]);
      setLoadingMessage((messages) => [...messages, "Purchasing"]);
    },
    [items]
  );

  const handleEquipItem = () => {
    setNotification((notifications) => [
      ...notifications,
      `You equipped ${equipItems.length} items!`,
    ]);
    setLoadingMessage((messages) => [...messages, "Equipping"]);
  };

  const handleDropItems = () => {
    setNotification((notifications) => [
      ...notifications,
      `You dropped ${dropItems.length} items!`,
    ]);
    setLoadingMessage((messages) => [...messages, "Dropping"]);
  };

  const handleUpgradeAdventurer = () => {
    setNotification((notifications) => [
      ...notifications,
      {
        Stats: upgrades,
        Items: purchaseItems,
        Potions: potionAmount,
      },
    ]);
    setLoadingMessage((messages) => [...messages, "Upgrading"]);
  };

  const handleSlayIdleAdventurers = useCallback((call: any) => {
    setNotification((notifications) => [
      ...notifications,
      `You slayed ${
        Array.isArray(call.calldata) && call.calldata[0]
      } Adventurers`,
    ]);
    setLoadingMessage((messages) => [...messages, "Slaying Adventurer"]);
  }, []);

  const prevCallsRef = useRef<Call[]>([]);

  const handleLoadData = useCallback(() => {
    const prevCalls = prevCallsRef.current;

    const addedCalls = calls.filter((call) => !prevCalls.includes(call));
    addedCalls.forEach((call) => {
      switch (call.entrypoint) {
        case "buy_item":
          handleBuyItem(call);
          break;
        case "equip":
          handleEquipItem();
          break;
        case "drop":
          handleDropItems();
          break;
        case "upgrade":
          handleUpgradeAdventurer();
          break;
        case "slay_idle_adventurers":
          handleSlayIdleAdventurers(call);
          break;
        default:
          break;
      }
    });

    prevCallsRef.current = calls;
  }, [
    calls,
    handleBuyItem,
    handleEquipItem,
    handleDropItems,
    handleUpgradeAdventurer,
    handleSlayIdleAdventurers,
  ]);

  useEffect(() => {
    handleLoadData();
  }, [calls]);

  const handleResetCalls = () => {
    resetCalls();
    setEquipItems([]);
    setDropItems([]);
    setPotionAmount(0);
    setPurchaseItems([]);
    setUpgrades({ ...ZeroUpgrade });
    setUpgradeScreen(1);
    setSlayAdventurers([]);
  };

  const handleAddUpgradeTx = (
    currentUpgrades?: UpgradeStats,
    potions?: number,
    items?: any[]
  ) => {
    removeEntrypointFromCalls("upgrade");
    const upgradeTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "upgrade",
      calldata: [
        adventurer?.id?.toString() ?? "",
        potions! >= 0 ? potions?.toString() : potionAmount.toString(),
        currentUpgrades
          ? currentUpgrades["Strength"].toString()
          : upgrades["Strength"].toString(),
        currentUpgrades
          ? currentUpgrades["Dexterity"].toString()
          : upgrades["Dexterity"].toString(),
        currentUpgrades
          ? currentUpgrades["Vitality"].toString()
          : upgrades["Vitality"].toString(),
        currentUpgrades
          ? currentUpgrades["Intelligence"].toString()
          : upgrades["Intelligence"].toString(),
        currentUpgrades
          ? currentUpgrades["Wisdom"].toString()
          : upgrades["Wisdom"].toString(),
        currentUpgrades
          ? currentUpgrades["Charisma"].toString()
          : upgrades["Charisma"].toString(),
        "0",
        items ? items.length.toString() : purchaseItems.length.toString(),
        ...(items
          ? items.flatMap(Object.values)
          : purchaseItems.flatMap(Object.values)),
      ],
    };
    addToCalls(upgradeTx);
  };

  const handleSubmitMulticall = async () => {
    resetNotification();
    // Handle for vitBoostRemoval
    let upgradeTx: any;
    if (potionAmount > 0) {
      // Check whether health + pots is within vitBoostRemoved of the maxHealth
      const maxHealth = 100 + totalVitality * vitalityIncrease;
      const newMaxHealth =
        100 + (totalVitality - vitBoostRemoved) * vitalityIncrease;
      const currentHealth =
        adventurer?.health! + selectedVitality * vitalityIncrease;
      const healthPlusPots = Math.min(
        currentHealth! + potionAmount * 10,
        maxHealth
      );
      const healthOverflow = healthPlusPots > newMaxHealth;
      if (healthOverflow) {
        const newUpgradeTx = handleAddUpgradeTx(
          undefined,
          Math.max(potionAmount - vitBoostRemoved, 0),
          undefined
        );
        upgradeTx = newUpgradeTx;
      }
    }
    setDisplayCart(false);
    await multicall(loadingMessage, notification, upgradeTx);
    handleResetCalls();
  };

  const { addControl } = useController();

  useEffect(() => {
    addControl("i", () => {
      console.log("Key i pressed");
      if (calls.length > 0) {
        handleSubmitMulticall();
        clickPlay();
      }
    });
  }, [calls, notification]);

  useEffect(() => {
    setNotification([]);
  }, [notificationData]);

  return (
    <div className="flex flex-row justify-between px-1 h-10 ">
      <div className="flex flex-row items-center gap-2 sm:gap-5">
        <Logo className="fill-current w-24 md:w-32 xl:w-40 2xl:w-72 2xl:mb-5" />
      </div>
      <div className="flex flex-row items-center self-end sm:gap-1 self-center">
        <Button
          className="sm:hidden px-2.5 sm:px-3 h-12 shadow-md"
          variant="token"
          onClick={() => showEncounterTable(!encounterTable)}
        >
          Prescience
        </Button>
        <ApibaraStatus status={apibaraStatus} />
        <Button
          size={"xs"}
          variant={"outline"}
          className="hidden sm:block self-center xl:px-5"
          onClick={() => {
            if (onMainnet) {
              setNetwork("katana");
            } else {
              handleOffboarded();
              setLoginScreen(true);
              setNetwork("sepolia");
            }
          }}
          disabled
        >
          {onMainnet ? "Play on Testnet" : "Play on Mainnet"}
        </Button>
        {!onKatana && (
          <>
            <Button
              size={"xs"}
              variant={"outline"}
              className="self-center xl:px-5"
            >
              <span className="flex flex-row items-center justify-between w-full">
                <Eth className="self-center sm:w-5 sm:h-5  h-3 w-3 fill-current mr-1" />
                <p>
                  {formatNumber(parseInt(ethBalance.toString()) / 10 ** 18)}
                </p>
              </span>
            </Button>
            <Button
              size={"xs"}
              variant={"outline"}
              className="self-center xl:px-5 hover:bg-terminal-green"
              onClick={async () => {
                if (onMainnet) {
                  const avnuLords = `https://app.avnu.fi/en?tokenFrom=${indexAddress(
                    networkConfig[network!].ethAddress ?? ""
                  )}&tokenTo=${indexAddress(
                    networkConfig[network!].lordsAddress ?? ""
                  )}&amount=0.001`;
                  window.open(avnuLords, "_blank");
                } else {
                  setMintingLords(true);
                  await mintLords(lordsGameCost * 25);
                  setMintingLords(false);
                }
              }}
              onMouseEnter={() => setShowLordsBuy(true)}
              onMouseLeave={() => setShowLordsBuy(false)}
            >
              <span className="flex flex-row items-center justify-between w-full">
                {!showLordsBuy ? (
                  <>
                    <Lords className="self-center sm:w-5 sm:h-5  h-3 w-3 fill-current mr-1" />
                    <p>
                      {formatNumber(
                        parseInt(lordsBalance.toString()) / 10 ** 18
                      )}
                    </p>
                  </>
                ) : (
                  <p className="text-black">
                    {onMainnet ? "Buy Lords" : "Mint Lords"}
                  </p>
                )}
              </span>
            </Button>
          </>
        )}
        <Button
          size={"xs"}
          variant={"outline"}
          onClick={() => {
            setIsMuted(!isMuted);
            clickPlay();
          }}
          className="hidden sm:block xl:px-5"
        >
          {isMuted ? (
            <SoundOffIcon className="sm:w-5 sm:h-5 h-3 w-3 justify-center fill-current" />
          ) : (
            <SoundOnIcon className="sm:w-5 sm:h-5 h-3 w-3 justify-center fill-current" />
          )}
        </Button>
        {account && (
          <>
            <span className="sm:hidden w-5 h-5 mx-2">
              <Button
                variant={"outline"}
                size={"fill"}
                ref={displayCartButtonRef}
                onClick={() => {
                  setDisplayCart(!displayCart);
                  clickPlay();
                }}
                className={`xl:px-5 ${txInCart ? "animate-pulse" : ""}`}
              >
                <CartIcon className="w-5 h-5 fill-current" />
              </Button>
            </span>
            <Button
              variant={txInCart ? "default" : "outline"}
              size={"xs"}
              ref={displayCartButtonRef}
              onClick={() => {
                setDisplayCart(!displayCart);
                clickPlay();
              }}
              className={`hidden sm:block xl:px-5 ${
                txInCart ? "animate-pulse" : ""
              }`}
            >
              <CartIcon className="w-5 h-5 fill-current" />
            </Button>
          </>
        )}
        {displayCart && (
          <TransactionCart
            buttonRef={displayCartButtonRef}
            handleSubmitMulticall={handleSubmitMulticall}
            handleAddUpgradeTx={handleAddUpgradeTx}
            handleResetCalls={handleResetCalls}
          />
        )}
        <span className="sm:hidden flex flex-row gap-2 items-center">
          <div className="relative">
            <Button
              variant={"outline"}
              size={"sm"}
              onClick={() => {
                disconnect();
                resetData();
                setAdventurer(NullAdventurer);
                setDisconnected(true);
              }}
              className="xl:px-5 p-0"
            >
              {account ? displayAddress(account.address) : "Connect"}
            </Button>
          </div>
          <Button
            size={"fill"}
            variant={"outline"}
            onClick={() => {
              setScreen("settings");
              clickPlay();
            }}
            className="xl:px-5"
          >
            <SettingsIcon className="fill-current h-5 w-5" />
          </Button>
        </span>
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
                className="xl:px-5"
              >
                {displayHistory ? "Hide Ledger" : "Show Ledger"}
              </Button>
            </>
          )}
          <div className="relative">
            <Button
              variant={"outline"}
              size={"sm"}
              onClick={() => {
                disconnect();
                resetData();
                setAdventurer(NullAdventurer);
                setDisconnected(true);
              }}
              className="xl:px-5"
            >
              {account ? displayAddress(account.address) : "Connect"}
            </Button>
            {checkCartridge && (
              <div className="absolute top-0 right-0">
                <svg viewBox="0 0 24 24" className="w-6 h-6">
                  <path
                    d="M8.45902 10.4506H15.4672V8.68029H8.46078C8.46078 8.86117 8.45902 10.4673 8.45902 10.4506Z"
                    fill="currentColor"
                  />
                  <path
                    d="M20.3231 6.80379L16.0408 4.99643C15.7594 4.85895 15.4523 4.782 15.1394 4.77051H8.86057C8.54749 4.78202 8.24026 4.85897 7.95857 4.99643L3.67686 6.80379C3.46971 6.90946 3.2964 7.07143 3.17675 7.27118C3.05709 7.47094 2.99591 7.70042 3.00021 7.93338V15.164C3.00021 15.3899 3.00021 15.6158 3.22556 15.8418L4.57827 17.1973C4.80362 17.4232 4.97279 17.4232 5.25433 17.4232H8.35191C8.35191 17.6174 8.35191 19.247 8.35191 19.2294H15.6744V17.4208H8.35776V15.6158H5.02897C4.80362 15.6158 4.80362 15.3899 4.80362 15.3899V6.80379C4.80362 6.80379 4.80362 6.57787 5.02897 6.57787H18.9716C19.197 6.57787 19.197 6.80379 19.197 6.80379V15.3899C19.197 15.3899 19.197 15.6158 18.9716 15.6158H15.6762V17.4232H18.7463C19.0278 17.4232 19.197 17.4232 19.4223 17.1973L20.7744 15.8418C20.9998 15.6158 20.9998 15.3899 20.9998 15.164V7.93338C21.004 7.70043 20.9428 7.47098 20.8232 7.27124C20.7035 7.0715 20.5302 6.90951 20.3231 6.80379Z"
                    fill="currentColor"
                  />
                </svg>
              </div>
            )}
          </div>

          <Button
            variant={"outline"}
            size={"sm"}
            href="https://github.com/BibliothecaDAO/loot-survivor"
            className="xl:px-5"
          >
            <GithubIcon className="w-6 fill-current" />
          </Button>
        </div>
        {account && displayHistory && (
          <TransactionHistory buttonRef={displayHistoryButtonRef} />
        )}
        {mintingLords && <TokenLoader isToppingUpLords={mintingLords} />}
      </div>
    </div>
  );
}
