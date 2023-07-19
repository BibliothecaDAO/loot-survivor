import { ReactElement, useState } from "react";
import { useContracts } from "../hooks/useContracts";
import {
  getKeyFromValue,
  getItemData,
  getValueFromKey,
  getItemPrice,
  padAddress,
} from "../lib/utils";
import { GameData } from "../components/GameData";
import VerticalKeyboardControl from "../components/menu/VerticalMenu";
import { useTransactionManager, useContractWrite } from "@starknet-react/core";
import useCustomQuery from "../hooks/useCustomQuery";
import {
  getAdventurerById,
  getLatestMarketItems,
} from "../hooks/graphql/queries";
import useLoadingStore from "../hooks/useLoadingStore";
import useAdventurerStore from "../hooks/useAdventurerStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import Info from "../components/adventurer/Info";
import { Button } from "../components/buttons/Button";
import { useMediaQuery } from "react-responsive";
import {
  ArrowTargetIcon,
  CatIcon,
  CoinIcon,
  CoinCharismaIcon,
  HeartVitalityIcon,
  LightbulbIcon,
  ScrollIcon,
  ArrowIcon,
} from "../components/icons/Icons";
import PurchaseHealth from "../components/actions/PurchaseHealth";
import MarketplaceScreen from "./MarketplaceScreen";
import { UpgradeNav } from "../components/upgrade/UpgradeNav";
import { useQueriesStore } from "../hooks/useQueryStore";

/**
 * @container
 * @description Provides the upgrade screen for the adventurer.
 */
export default function UpgradeScreen() {
  const { gameContract } = useContracts();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const currentLevel = useAdventurerStore(
    (state) => state.computed.currentLevel
  );
  const startLoading = useLoadingStore((state) => state.startLoading);
  const setTxHash = useLoadingStore((state) => state.setTxHash);
  const loading = useLoadingStore((state) => state.loading);
  const txAccepted = useLoadingStore((state) => state.txAccepted);
  const { addTransaction } = useTransactionManager();
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const hash = useLoadingStore((state) => state.hash);
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const hasStatUpgrades = useAdventurerStore(
    (state) => state.computed.hasStatUpgrades
  );
  const { writeAsync } = useContractWrite({ calls });
  const [selected, setSelected] = useState("");
  const maxHealth = 100 + (adventurer?.vitality ?? 0) * 20;
  const [upgradeScreen, setUpgradeScreen] = useState(
    adventurer?.health == maxHealth ? 2 : 1
  );

  const { data, resetDataUpdated } = useQueriesStore();

  const gameData = new GameData();

  useCustomQuery(
    "adventurerByIdQuery",
    getAdventurerById,
    {
      id: adventurer?.id ?? 0,
    },
    txAccepted
  );

  console.log(adventurer?.id ?? 0);
  console.log(txAccepted);
  console.log(data.adventurerByIdQuery?.adventurers[0]);

  useCustomQuery(
    "latestMarketItemsQuery",
    getLatestMarketItems,
    {
      adventurerId: adventurer?.id,
    },
    txAccepted
  );

  const handleUpgradeTx = async (selected: any) => {
    const upgradeTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "upgrade_stat",
      calldata: [
        adventurer?.id?.toString() ?? "",
        "0",
        getKeyFromValue(gameData.STATS, selected) ?? "",
        "1",
      ],
    };
    addToCalls(upgradeTx);
    startLoading(
      "Upgrade",
      `Upgrading ${selected}`,
      "adventurerByIdQuery",
      adventurer?.id,
      `You upgraded ${selected}!`
    );
    handleSubmitCalls(writeAsync).then((tx: any) => {
      if (tx) {
        setTxHash(tx.transaction_hash);
        addTransaction({
          hash: tx.transaction_hash,
          metadata: {
            method: "Upgrade Stat",
            description: `Upgrading ${selected}`,
          },
        });
      }
    });
    resetDataUpdated("adventurerByIdQuery");
  };

  const Attribute = ({ name, description, buttonText }: any): ReactElement => (
    <div className="flex flex-col gap-3 items-center">
      <p className="sm:text-[28px] text-center">{description}</p>
      <Button onClick={() => handleUpgradeTx(name)}>{buttonText}</Button>
    </div>
  );

  const attributes = [
    {
      name: "Strength",
      description: "Strength increases attack damage by 10%",
      buttonText: "Upgrade Strength",
    },
    {
      name: "Dexterity",
      description: "Dexterity increases chance of fleeing Beasts",
      buttonText: "Upgrade Dexterity",
    },
    {
      name: "Vitality",
      description: "Vitality increases max health by 20hp",
      buttonText: "Upgrade Vitality",
    },
    {
      name: "Intelligence",
      description: "Intelligence increases chance of avoiding Obstacles",
      buttonText: "Upgrade Intelligence",
    },
    {
      name: "Wisdom",
      description: "Wisdom increases chance of avoiding a Beast ambush",
      buttonText: "Upgrade Wisdom",
    },
    {
      name: "Charisma",
      description: "Charisma provides discounts on the marketplace and potions",
      buttonText: "Upgrade Charisma",
    },
  ];

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  const previousLevel = currentLevel - (adventurer?.statUpgrades ?? 0);

  function renderContent() {
    const attribute = attributes.find((attr) => attr.name === selected);
    return (
      <div className="flex sm:w-2/3 items-center justify-center border-l border-terminal-green p-2">
        {attribute && <Attribute {...attribute} />}
      </div>
    );
  }

  function renderVerticalKeyboardControl() {
    const upgradeMenu = [
      {
        id: 1,
        label: `Strength - ${adventurer?.strength}`,
        icon: <ArrowTargetIcon />,
        value: "Strength",
        action: async () => setSelected("Strength"),
        disabled: loading,
      },
      {
        id: 2,
        label: `Dexterity - ${adventurer?.dexterity}`,
        icon: <CatIcon />,
        value: "Dexterity",
        action: async () => setSelected("Dexterity"),
        disabled: loading,
      },
      {
        id: 3,
        label: `Vitality - ${adventurer?.vitality}`,
        icon: <HeartVitalityIcon />,
        value: "Vitality",
        action: async () => setSelected("Vitality"),
        disabled: loading,
      },
      {
        id: 4,
        label: `Intelligence - ${adventurer?.intelligence}`,
        icon: <LightbulbIcon />,
        value: "Intelligence",
        action: async () => setSelected("Intelligence"),
        disabled: loading,
      },
      {
        id: 5,
        label: `Wisdom - ${adventurer?.wisdom}`,
        icon: <ScrollIcon />,
        value: "Wisdom",
        action: async () => setSelected("Wisdom"),
        disabled: loading,
      },
      {
        id: 6,
        label: `Charisma - ${adventurer?.charisma}`,
        icon: <CoinCharismaIcon />,
        value: "Charisma",
        action: async () => setSelected("Charisma"),
        disabled: loading,
      },
    ];
    return (
      <div className="sm:w-1/3">
        <VerticalKeyboardControl
          buttonsData={upgradeMenu}
          onSelected={setSelected}
          onEnterAction={true}
        />
      </div>
    );
  }

  const itemsFilter = calls.filter((call) => call.entrypoint === "buy_item");

  const potionsCall = calls.find((call) => call.entrypoint === "buy_potions");

  const potionsFilter =
    potionsCall &&
    Array.isArray(potionsCall.calldata) &&
    potionsCall.calldata[2];

  const getPurchasedGoldSum = () => {
    if (potionsCall) {
      const value = potionsFilter;
      const parsedValue = value ? parseInt(value.toString(), 10) : 0;
      const purchaseGoldAmount = Math.max(
        parsedValue * currentLevel - 2 * (adventurer?.charisma ?? 0),
        2
      );
      return purchaseGoldAmount;
    } else {
      return 0;
    }
  };

  const itemsGoldSum = itemsFilter.reduce((accumulator, current) => {
    const value = Array.isArray(current.calldata) && current.calldata[2];
    const parsedValue = value ? parseInt(value.toString(), 10) : 0;
    const { tier } = getItemData(
      getValueFromKey(gameData.ITEMS, parsedValue) ?? ""
    );
    const itemPrice = getItemPrice(tier, adventurer?.charisma ?? 0);
    return accumulator + (isNaN(itemPrice) ? 0 : itemPrice);
  }, 0);

  const upgradeTotalCost = getPurchasedGoldSum() + itemsGoldSum;

  return (
    <>
      {hasStatUpgrades ? (
        <div className="flex flex-col sm:flex-row gap-2">
          <div className="w-1/3 hidden sm:block">
            <Info adventurer={adventurer} />
          </div>
          <div className="w-full sm:w-2/3">
            <div className="flex flex-col gap-2 h-full">
              <div className="flex flex-col items-center gap-2 border-terminal-green">
                <div className="flex flex-col items-center justify-center text-terminal-green space-x-3">
                  <div className="text-center text-lg md:text-xl lg:text-4xl p-2 animate-pulse uppercase">
                    Level up!
                  </div>
                  <div className="flex flex-row gap-2 text-2xl text-shadow-none">
                    {previousLevel}
                    <span className="w-5">
                      <ArrowIcon />
                    </span>
                    {currentLevel}
                  </div>
                  <div className="flex flex-row gap-10 text-sm sm:text-base">
                    <div className="flex flex-row gap-3">
                      <span className="flex flex-row gap-1  items-center">
                        <p className="uppercase">Cost:</p>
                        <span className="flex text-xl">
                          <CoinIcon className="self-center w-5 h-5 fill-current text-terminal-yellow" />
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
                      <span className="flex flex-row gap-1  items-center">
                        <p className="uppercase">Potions:</p>
                        <span className="flex text-xl text-terminal-yellow">
                          {potionsFilter ?? 0}
                        </span>
                      </span>
                      <span className="flex flex-row gap-1 items-center">
                        <p className="uppercase">Items:</p>
                        <span className="flex text-xl text-terminal-yellow">
                          {itemsFilter.length}
                        </span>
                      </span>
                    </div>
                    <div>
                      <span className="flex flex-row sm:gap-1">
                        {`Charisma: ${adventurer?.charisma} -`}
                        <CoinIcon className="w-5 h-5 fill-current text-terminal-yellow" />
                        <p className="text-terminal-yellow">
                          {adventurer?.charisma && adventurer?.charisma * 2}
                        </p>
                        <p className="hidden sm:block">{" to price"}</p>
                      </span>
                    </div>
                  </div>
                  <UpgradeNav activeSection={upgradeScreen} />
                </div>

                {upgradeScreen == 1 && (
                  <div className="w-full sm:w-2/3 border-terminal-green border p-2">
                    <p className="text-center text-lg sm:text-2xl lg:text-4xl">
                      Potions
                    </p>
                    <PurchaseHealth upgradeTotalCost={upgradeTotalCost} />
                  </div>
                )}

                {upgradeScreen == 2 && (
                  <div className="flex flex-col gap-2 w-full">
                    <div className="w-full border-terminal-green border sm:p-4">
                      <MarketplaceScreen upgradeTotalCost={upgradeTotalCost} />
                    </div>
                  </div>
                )}
              </div>
              {upgradeScreen == 3 && (
                <div className="flex flex-col gap-5 sm:gap-0 sm:flex-row w-full border-terminal-green border">
                  {isMobileDevice ? (
                    <>
                      {renderContent()}
                      {renderVerticalKeyboardControl()}
                    </>
                  ) : (
                    <>
                      {renderVerticalKeyboardControl()}
                      {renderContent()}
                    </>
                  )}
                </div>
              )}
              <div className="w-1/2 flex flex-row gap-2 mx-auto">
                <Button
                  className="w-1/2"
                  onClick={() => setUpgradeScreen(upgradeScreen - 1)}
                  disabled={upgradeScreen == 1}
                >
                  Back
                </Button>
                <Button
                  className="w-1/2"
                  onClick={() => setUpgradeScreen(upgradeScreen + 1)}
                  disabled={upgradeScreen == 3}
                >
                  Next
                </Button>
              </div>
            </div>
          </div>
        </div>
      ) : (
        <h1 className="mx-auto">No upgrades available!</h1>
      )}
    </>
  );
}
