import { ReactElement, useState, useEffect } from "react";
import { useContracts } from "../hooks/useContracts";
import { getKeyFromValue, calculateLevel } from "../lib/utils";
import { GameData } from "../components/GameData";
import VerticalKeyboardControl from "../components/menu/VerticalMenu";
import { useTransactionManager, useContractWrite } from "@starknet-react/core";
import useCustomQuery from "../hooks/useCustomQuery";
import { getAdventurerById } from "../hooks/graphql/queries";
import useLoadingStore from "../hooks/useLoadingStore";
import useAdventurerStore from "../hooks/useAdventurerStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import useUIStore from "../hooks/useUIStore";
import Info from "../components/adventurer/Info";
import { Button } from "../components/buttons/Button";
import { useMediaQuery } from "react-responsive";
import {
  ArrowTargetIcon,
  CatIcon,
  CoinCharismaIcon,
  HeartVitalityIcon,
  LightbulbIcon,
  ScrollIcon,
  ArrowIcon,
} from "../components/icons/Icons";
import PurchaseHealth from "../components/actions/PurchaseHealth";
import MarketplaceScreen from "./MarketplaceScreen";

/**
 * @container
 * @description Provides the upgrade screen for the adventurer.
 */
export default function UpgradeScreen() {
  const { gameContract } = useContracts();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const startLoading = useLoadingStore((state) => state.startLoading);
  const setTxHash = useLoadingStore((state) => state.setTxHash);
  const loading = useLoadingStore((state) => state.loading);
  const txAccepted = useLoadingStore((state) => state.txAccepted);
  const { addTransaction } = useTransactionManager();
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const { writeAsync } = useContractWrite({ calls });
  const setScreen = useUIStore((state) => state.setScreen);
  // const purchasedItem = useUIStore((state) => state.purchasedItem);
  const [selected, setSelected] = useState("");
  const statUpgrades = adventurer?.statUpgrades ?? 0;

  useCustomQuery(
    "adventurerByIdQuery",
    getAdventurerById,
    {
      id: adventurer?.id ?? 0,
    },
    true
  );

  const gameData = new GameData();

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

  const handleUpgradeTx = async (selected: any) => {
    const upgradeTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "upgrade_stat",
      calldata: [
        adventurer?.id?.toString() ?? "",
        "0",
        getKeyFromValue(gameData.STATS, selected) ?? "",
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
        setTxHash(tx?.transaction_hash);
        addTransaction({
          hash: tx.transaction_hash,
          metadata: {
            method: "Upgrade Stat",
            description: `Upgrading ${selected}`,
          },
        });
      }
    });
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

  useEffect(() => {
    if (statUpgrades == 0) {
      setScreen("play");
    }
  }, [statUpgrades, setScreen]);

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  const currentLevel = adventurer?.level ?? 0;

  const previousLevel = currentLevel - statUpgrades;

  function renderContent() {
    const attribute = attributes.find((attr) => attr.name === selected);
    return (
      <div className="flex sm:w-2/3 items-center justify-center border-l border-terminal-green p-2">
        {attribute && <Attribute {...attribute} />}
      </div>
    );
  }

  function renderVerticalKeyboardControl() {
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

  return (
    <div className="flex flex-col sm:flex-row gap-2">
      <div className="w-1/3 hidden sm:block">
        <Info adventurer={adventurer} />
      </div>
      <div className="w-full sm:w-2/3">
        <div className="flex flex-col gap-2 h-full">
          <div className="flex flex-col items-center gap-2 border-terminal-green sm:p-4">
            {/* <div className="flex flew row w-full"> */}
            <div className="flex flex-col items-center justify-center text-terminal-green space-x-3">
              <div className="text-center text-lg md:text-xl lg:text-4xl  p-2 animate-pulse">
                Adventurer Level up!
              </div>
              <p className="text-2xl">
                {previousLevel} {" -> "}
                {currentLevel}
              </p>
              <div className="text-center text-xs md:text-l lg:text-xl p-2 animate-pulse">
                Fountain stops after upgrade
              </div>
            </div>

            <div className="w-full sm:w-2/3 border-terminal-green border p-2">
              <p className="text-center text-lg sm:text-2xl lg:text-4xl">
                Potions
              </p>
              <PurchaseHealth />
            </div>
            {/* </div> */}

            <div className="flex flex-col gap-2 w-full">
              <div className="w-full border-terminal-green border sm:p-4">
                <MarketplaceScreen />
              </div>
            </div>
          </div>
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
        </div>
      </div>
    </div>
  );
}
