import { useEffect, useState } from "react";
import { CallData, Contract } from "starknet";
import {
  getItemData,
  getValueFromKey,
  getItemPrice,
  getPotionPrice,
} from "@/app/lib/utils";
import { GameData } from "@/app/lib/data/GameData";
import ButtonMenu from "@/app/components/menu/ButtonMenu";
import useLoadingStore from "@/app/hooks/useLoadingStore";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import Info from "@/app/components/adventurer/Info";
import { Button } from "@/app/components/buttons/Button";
import {
  ArrowTargetIcon,
  CatIcon,
  CoinIcon,
  CoinCharismaIcon,
  HeartVitalityIcon,
  LightbulbIcon,
  ScrollIcon,
  HeartIcon,
} from "@/app/components/icons/Icons";
import PurchaseHealth from "@/app/components/upgrade/PurchaseHealth";
import MarketplaceScreen from "@/app/containers/MarketplaceScreen";
import { UpgradeNav } from "@/app/components/upgrade/UpgradeNav";
import { StatAttribute } from "@/app/components/upgrade/StatAttribute";
import useUIStore from "@/app/hooks/useUIStore";
import {
  UpgradeStats,
  ZeroUpgrade,
  UpgradeSummary,
  ItemPurchase,
} from "@/app/types";
import Summary from "@/app/components/upgrade/Summary";
import { HealthCountDown } from "@/app/components/CountDown";
import { calculateVitBoostRemoved } from "@/app/lib/utils";
import { useQueriesStore } from "@/app/hooks/useQueryStore";

interface UpgradeScreenProps {
  upgrade: (
    upgrades: UpgradeStats,
    purchaseItems: ItemPurchase[],
    potionAmount: number,
    upgradeTx?: any
  ) => Promise<void>;
  gameContract: Contract;
}

/**
 * @container
 * @description Provides the upgrade screen for the adventurer.
 */
export default function UpgradeScreen({
  upgrade,
  gameContract,
}: UpgradeScreenProps) {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const loading = useLoadingStore((state) => state.loading);
  const estimatingFee = useUIStore((state) => state.estimatingFee);
  const resetNotification = useLoadingStore((state) => state.resetNotification);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const removeEntrypointFromCalls = useTransactionCartStore(
    (state) => state.removeEntrypointFromCalls
  );
  const hasStatUpgrades = useAdventurerStore(
    (state) => state.computed.hasStatUpgrades
  );
  const [selected, setSelected] = useState("");
  const [nonBoostedStats, setNonBoostedStats] = useState<any | null>(null);
  const upgradeScreen = useUIStore((state) => state.upgradeScreen);
  const setUpgradeScreen = useUIStore((state) => state.setUpgradeScreen);
  const potionAmount = useUIStore((state) => state.potionAmount);
  const setPotionAmount = useUIStore((state) => state.setPotionAmount);
  const upgrades = useUIStore((state) => state.upgrades);
  const setUpgrades = useUIStore((state) => state.setUpgrades);
  const purchaseItems = useUIStore((state) => state.purchaseItems);
  const setPurchaseItems = useUIStore((state) => state.setPurchaseItems);
  const pendingMessage = useLoadingStore((state) => state.pendingMessage);
  const [summary, setSummary] = useState<UpgradeSummary>({
    Stats: { ...ZeroUpgrade },
    Items: [],
    Potions: 0,
  });

  const gameData = new GameData();

  const checkTransacting =
    typeof pendingMessage === "string" &&
    (pendingMessage as string).startsWith("Upgrading");

  const attributes = [
    {
      name: "Strength",
      icon: <ArrowTargetIcon />,
      description: "Strength increases attack damage by 10%",
      buttonText: "Upgrade Strength",
      abbrev: "STR",
      nonBoostedStat: nonBoostedStats?.strength,
    },
    {
      name: "Dexterity",
      icon: <CatIcon />,
      description: "Dexterity increases chance of fleeing Beasts",
      buttonText: "Upgrade Dexterity",
      abbrev: "DEX",
      nonBoostedStat: nonBoostedStats?.dexterity,
    },
    {
      name: "Vitality",
      id: 3,
      icon: <HeartVitalityIcon />,
      description: "Vitality increases max health and gives +10hp ",
      buttonText: "Upgrade Vitality",
      abbrev: "VIT",
      nonBoostedStat: nonBoostedStats?.vitality,
    },
    {
      name: "Intelligence",
      icon: <LightbulbIcon />,
      description: "Intelligence increases chance of avoiding Obstacles",
      buttonText: "Upgrade Intelligence",
      abbrev: "INT",
      nonBoostedStat: nonBoostedStats?.intelligence,
    },
    {
      name: "Wisdom",
      icon: <ScrollIcon />,
      description: "Wisdom increases chance of avoiding a Beast ambush",
      buttonText: "Upgrade Wisdom",
      abbrev: "WIS",
      nonBoostedStat: nonBoostedStats?.wisdom,
    },
    {
      name: "Charisma",
      icon: <CoinCharismaIcon />,
      description: "Charisma provides discounts on the marketplace and potions",
      buttonText: "Upgrade Charisma",
      abbrev: "CHA",
      nonBoostedStat: nonBoostedStats?.charisma,
    },
  ];

  function renderContent() {
    const attribute = attributes.find((attr) => attr.name === selected);
    return (
      <div className="order-1 sm:order-2 flex sm:w-2/3 h-24 sm:h-full items-center justify-center p-auto">
        {attribute && (
          <StatAttribute upgradeHandler={handleAddUpgradeTx} {...attribute} />
        )}
      </div>
    );
  }

  function renderButtonMenu() {
    const upgradeMenu = [
      {
        id: 1,
        label: `Strength - ${adventurer?.strength}`,
        icon: <ArrowTargetIcon />,
        value: "Strength",
        action: async () => setSelected("Strength"),
        disabled: false,
      },
      {
        id: 2,
        label: `Dexterity - ${adventurer?.dexterity}`,
        icon: <CatIcon />,
        value: "Dexterity",
        action: async () => setSelected("Dexterity"),
        disabled: false,
      },
      {
        id: 3,
        label: `Vitality - ${adventurer?.vitality}`,
        icon: <HeartVitalityIcon />,
        value: "Vitality",
        action: async () => setSelected("Vitality"),
        disabled: false,
      },
      {
        id: 4,
        label: `Intelligence - ${adventurer?.intelligence}`,
        icon: <LightbulbIcon />,
        value: "Intelligence",
        action: async () => setSelected("Intelligence"),
        disabled: false,
      },
      {
        id: 5,
        label: `Wisdom - ${adventurer?.wisdom}`,
        icon: <ScrollIcon />,
        value: "Wisdom",
        action: async () => setSelected("Wisdom"),
        disabled: false,
      },
      {
        id: 6,
        label: `Charisma - ${adventurer?.charisma}`,
        icon: <CoinCharismaIcon />,
        value: "Charisma",
        action: async () => setSelected("Charisma"),
        disabled: false,
      },
    ];
    return (
      <div className="order-2 sm:order-1 sm:w-1/3 sm:border-r sm:border-terminal-green h-full">
        <ButtonMenu
          buttonsData={upgradeMenu}
          onSelected={setSelected}
          onEnterAction={true}
          className="flex-col items-center justify-center h-full"
          size="lg"
        />
      </div>
    );
  }

  const selectedCharisma = upgrades["Charisma"] ?? 0;
  const selectedVitality = upgrades["Vitality"] ?? 0;

  const totalVitality = (adventurer?.vitality ?? 0) + selectedVitality;
  const totalCharisma = (adventurer?.charisma ?? 0) + selectedCharisma;

  const purchaseGoldAmount =
    potionAmount * getPotionPrice(adventurer?.level ?? 0, totalCharisma);

  const itemsGoldSum = purchaseItems.reduce((accumulator, current) => {
    const { tier } = getItemData(
      getValueFromKey(gameData.ITEMS, parseInt(current.item)) ?? ""
    );
    const itemPrice = getItemPrice(tier, totalCharisma);
    return accumulator + (isNaN(itemPrice) ? 0 : itemPrice);
  }, 0);

  const upgradeTotalCost = purchaseGoldAmount + itemsGoldSum;

  const handleAddUpgradeTx = (
    currentUpgrades?: UpgradeStats,
    potions?: number,
    items?: ItemPurchase[]
  ) => {
    removeEntrypointFromCalls("upgrade");
    const upgradeTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "upgrade",
      calldata: [
        adventurer?.id?.toString() ?? "",
        potions !== undefined ? potions.toString() : potionAmount.toString(),
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
    return upgradeTx;
  };

  const handleSubmitUpgradeTx = async () => {
    renderSummary();
    resetNotification();
    // Handle for vitBoostRemoval
    const vitBoostRemoved = calculateVitBoostRemoved(
      purchaseItems,
      adventurer!,
      adventurerItems
    );
    let upgradeTx: any;
    if (potionAmount > 0) {
      // Check whether health + pots is within vitBoostRemoved of the maxHealth
      const maxHealth = 100 + totalVitality * 10;
      const newMaxHealth = 100 + (totalVitality - vitBoostRemoved) * 10;
      const currentHealth = adventurer?.health! + selectedVitality * 10;
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
    try {
      await upgrade(
        upgrades,
        purchaseItems,
        Math.max(potionAmount - vitBoostRemoved, 0),
        upgradeTx
      );
      setPotionAmount(0);
      setPurchaseItems([]);
      setUpgrades({ ...ZeroUpgrade });
    } catch (e) {
      console.log(e);
    }
  };

  const upgradesTotal = Object.values(upgrades)
    .filter((value) => value !== 0)
    .reduce((accumulator, currentValue) => accumulator + currentValue, 0);

  const nextDisabled = upgradesTotal !== adventurer?.statUpgrades;

  useEffect(() => {
    if (upgrades.length === 0) {
      setUpgradeScreen(1);
    }
  }, [upgrades]);

  const renderSummary = () => {
    setSummary({
      Stats: upgrades,
      Items: purchaseItems,
      Potions: potionAmount,
    });
  };

  const totalStatUpgrades = (adventurer?.statUpgrades ?? 0) - upgradesTotal;

  const maxHealth = Math.min(100 + totalVitality * 10, 720);

  const healthPlus = Math.min(
    (selectedVitality + potionAmount) * 10,
    maxHealth - (adventurer?.health ?? 0)
  );

  const maxHealthPlus = selectedVitality * 10;

  const totalHealth = Math.min(
    (adventurer?.health ?? 0) + healthPlus,
    maxHealth
  );

  const getNoBoostedStats = async () => {
    const stats = await gameContract?.call(
      "get_base_stats",
      CallData.compile({ token_id: adventurer?.id! })
    ); // check whether player can use the current token
    setNonBoostedStats(stats);
  };

  useEffect(() => {
    getNoBoostedStats();
  }, []);

  const adventurerItems = useQueriesStore(
    (state) => state.data.itemsByAdventurerQuery?.items || []
  );

  return (
    <>
      {hasStatUpgrades ? (
        <div className="flex flex-col sm:flex-row items-center sm:items-start gap-2 h-full">
          <div className="w-1/3 hidden sm:flex h-full">
            <Info
              adventurer={adventurer}
              upgradeCost={upgradeTotalCost}
              gameContract={gameContract}
            />
          </div>
          {!checkTransacting ? (
            <div className="w-full sm:w-2/3 h-full">
              <div className="flex flex-col gap-2 xl:gap-0 h-full">
                <div className="flex flex-col gap-2 sm:gap-0 justify-center text-terminal-green h-1/3 sm:h-1/4">
                  <div className="w-full flex flex-row gap-2 mx-auto border border-terminal-green justify-between">
                    <Button
                      variant={"outline"}
                      onClick={() => setUpgradeScreen(upgradeScreen - 1)}
                      disabled={upgradeScreen == 1}
                    >
                      {"<"} Back
                    </Button>

                    {upgradeScreen != 3 && (
                      <div className="sm:hidden flex-grow text-center uppercase text-2xl self-center">
                        Level up!
                      </div>
                    )}

                    {upgradeScreen != 3 && upgradeScreen != 2 && (
                      <div className=" flex-grow text-center uppercase text-2xl self-center hidden sm:block">
                        Level up!
                      </div>
                    )}

                    <Button
                      className={` ${
                        upgradeScreen == 2
                          ? "hidden sm:block"
                          : upgradeScreen == 3
                          ? "sm:hidden"
                          : "hidden"
                      } w-full`}
                      onClick={() => {
                        handleSubmitUpgradeTx();
                        setUpgradeScreen(1);
                      }}
                      disabled={nextDisabled || loading || estimatingFee}
                    >
                      {loading ? (
                        <span>Upgrading...</span>
                      ) : (
                        <span>Upgrade</span>
                      )}
                    </Button>
                    <Button
                      className={` ${
                        upgradeScreen == 2
                          ? "sm:hidden"
                          : upgradeScreen == 3
                          ? "hidden"
                          : ""
                      }`}
                      onClick={() => {
                        setUpgradeScreen(upgradeScreen + 1);
                      }}
                      disabled={nextDisabled || loading || estimatingFee}
                    >
                      <span>Next {">"}</span>
                    </Button>
                  </div>

                  <div className="flex flex-row gap-2 xl:gap-0 justify-center text-lg 2xl:text-2xl text-shadow-none">
                    <span>
                      {totalStatUpgrades > 0
                        ? `Stat Upgrades Available ${totalStatUpgrades}`
                        : "All Stats Chosen!"}
                    </span>
                  </div>
                  <UpgradeNav activeSection={upgradeScreen} />
                  <div className="flex flex-col text-sm sm:text-base items-center justify-center border border-terminal-green">
                    <div className="flex flex-row gap-3 border-b border-terminal-green w-full justify-center">
                      <span className="flex flex-row gap-1 items-center">
                        <p>Cost:</p>
                        <span className="flex flex-row items-center text-xl">
                          <CoinIcon className="self-center w-5 h-5 fill-current text-terminal-yellow self-center ml-1" />
                          <p
                            className={
                              upgradeTotalCost > (adventurer?.gold ?? 0)
                                ? "text-red-600"
                                : "text-terminal-yellow"
                            }
                          >
                            {upgradeTotalCost}
                          </p>
                        </span>
                      </span>
                      <span className="flex flex-row gap-1 items-center">
                        <p>Potions:</p>
                        <span className="flex text-xl text-terminal-yellow">
                          {potionAmount?.toString() ?? 0}
                        </span>
                      </span>
                      <span className="flex flex-row gap-1 items-center">
                        <p>Items:</p>
                        <span className="flex text-xl text-terminal-yellow">
                          {purchaseItems?.length}
                        </span>
                      </span>
                    </div>
                    <div className="sm:hidden flex flex-row gap-3 py-2 items-center text-lg">
                      <span className="flex flex-row">
                        Gold:{" "}
                        <span className="flex flex-row text-terminal-yellow">
                          <CoinIcon className="self-center mt-1 w-5 h-5 fill-current" />{" "}
                          {(adventurer?.gold ?? 0) - upgradeTotalCost}
                        </span>
                      </span>
                      <span className="relative flex flex-row items-center">
                        <span className="flex items-center ">
                          <HeartIcon className="self-center mt-1 w-5 h-5 fill-current" />{" "}
                          <HealthCountDown health={totalHealth || 0} />
                          {`/${maxHealth}`}
                        </span>
                        {(potionAmount > 0 || selectedVitality > 0) && (
                          <p className="absolute top-[-5px] sm:top-[-10px] right-[30px] sm:right-[40px] text-xs sm:text-sm">
                            +{healthPlus}
                          </p>
                        )}
                        {selectedVitality > 0 && (
                          <p className="absolute top-[-5px] sm:top-[-10px] right-0 text-xs sm:text-sm">
                            +{maxHealthPlus}
                          </p>
                        )}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="flex flex-col h-2/3 sm:h-3/4">
                  {upgradeScreen === 1 && (
                    <div className="flex flex-col sm:gap-2 items-center w-full h-full">
                      <div className="flex flex-col gap-0 sm:flex-row w-full border-terminal-green border sm:items-center h-full">
                        {renderContent()}
                        {renderButtonMenu()}
                      </div>
                    </div>
                  )}

                  {upgradeScreen === 2 && (
                    <div
                      className="flex
                     sm:flex-row items-center justify-center flex-wrap border border-terminal-green p-2 h-full sm:h-1/6"
                    >
                      {/* <h4>Potions</h4> */}
                      <PurchaseHealth
                        upgradeTotalCost={upgradeTotalCost}
                        potionAmount={potionAmount}
                        setPotionAmount={setPotionAmount}
                        totalCharisma={totalCharisma}
                        upgradeHandler={handleAddUpgradeTx}
                        totalVitality={totalVitality}
                      />
                    </div>
                  )}

                  {upgradeScreen === 2 && (
                    <div className="hidden sm:flex items-center w-full h-5/6">
                      <MarketplaceScreen
                        upgradeTotalCost={upgradeTotalCost}
                        purchaseItems={purchaseItems}
                        setPurchaseItems={setPurchaseItems}
                        upgradeHandler={handleAddUpgradeTx}
                        totalCharisma={totalCharisma}
                        adventurerItems={adventurerItems}
                      />
                    </div>
                  )}
                  {upgradeScreen === 3 && (
                    <div className="sm:hidden flex-col items-center sm:gap-2 w-full h-full">
                      <MarketplaceScreen
                        upgradeTotalCost={upgradeTotalCost}
                        purchaseItems={purchaseItems}
                        setPurchaseItems={setPurchaseItems}
                        upgradeHandler={handleAddUpgradeTx}
                        totalCharisma={totalCharisma}
                        adventurerItems={adventurerItems}
                      />
                    </div>
                  )}
                </div>
              </div>
            </div>
          ) : (
            <Summary summary={summary} attributes={attributes} />
          )}
        </div>
      ) : (
        <h1 className="mx-auto">No upgrades available!</h1>
      )}
    </>
  );
}
