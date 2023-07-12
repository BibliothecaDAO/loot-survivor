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
    txAccepted
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

  const Strength = (): ReactElement => (
    <div className="flex flex-col gap-3 items-center">
      <p className="sm:text-[28px] text-center">
        Strength increases attack damage by 10%
      </p>
      <Button onClick={() => handleUpgradeTx("Strength")}>
        Upgrade Strength
      </Button>
    </div>
  );
  const Dexterity = (): ReactElement => (
    <div className="flex flex-col gap-3 items-center">
      <p className="sm:text-[28px] text-center">
        Dexterity increases chance of fleeing Beasts
      </p>
      <Button onClick={() => handleUpgradeTx("Dexterity")}>
        Upgrade Dexterity
      </Button>
    </div>
  );
  const Vitality = (): ReactElement => (
    <div className="flex flex-col gap-3 items-center">
      <p className="sm:text-[28px] text-center">
        Vitality increases current and max health each by 20hp
      </p>
      <Button onClick={() => handleUpgradeTx("Vitality")}>
        Upgrade Vitality
      </Button>
    </div>
  );
  const Intelligence = (): ReactElement => (
    <div className="flex flex-col gap-3 items-center">
      <p className="sm:text-[28px] text-center">
        Intelligence increases chance of avoiding Obstacles
      </p>
      <Button onClick={() => handleUpgradeTx("Intelligence")}>
        Upgrade Intelligence
      </Button>
    </div>
  );
  const Wisdom = (): ReactElement => (
    <div className="flex flex-col gap-3 items-center">
      <p className="sm:text-[28px] text-center">
        Wisdom increases chance of avoiding a Beast ambush
      </p>
      <Button onClick={() => handleUpgradeTx("Wisdom")}>Upgrade Wisdom</Button>
    </div>
  );
  const Charisma = (): ReactElement => (
    <div className="flex flex-col gap-3 items-center">
      <p className="sm:text-[30px] text-center">
        Charisma provides discounts on the marketplace and potions
      </p>
      <Button onClick={() => handleUpgradeTx("Charisma")}>
        Upgrade Charisma
      </Button>
    </div>
  );

  useEffect(() => {
    if (statUpgrades == 0) {
      setScreen("actions");
    }
  }, [statUpgrades, setScreen]);

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  const currentLevel = adventurer?.level ?? 0;

  const previousLevel = currentLevel - statUpgrades;

  return (
    <div className="flex flex-col sm:flex-row">
      <div className="w-1/3 mr-5 hidden sm:block">
        <Info adventurer={adventurer} />
      </div>
      <div className="w-full sm:w-2/3">
        <div className="flex flex-col gap-5 sm:gap-10">
          <div className="flex flex-col gap-2 p-2 sm:p-10 items-center">
            <span className="flex flex-col gap-2 text-center text-4xl">
              <span className="animate-pulse">LEVEL UP!</span>
              <span className="flex flex-row items-center justify-center gap-2 text-terminal-yellow">
                {previousLevel}{" "}
                <span className="w-7 h-7">
                  <ArrowIcon />
                </span>{" "}
                {currentLevel}
              </span>
            </span>
            <p className="text-center text-lg sm:text-2xl">
              {/* {purchasedItem
                ? "You have purchased an item!"
                : "Items are on the market!"} */}
              Items are on the market!
            </p>
            <Button
              className="w-1/4"
              onClick={() => setScreen("market")}
              // disabled={purchasedItem}
            >
              Market
            </Button>
          </div>
          <div className="flex flex-col gap-5 sm:gap-0 sm:flex-row w-full">
            {isMobileDevice ? (
              <>
                <div className="flex sm:w-2/3 items-center justify-center border border-terminal-green p-2">
                  {selected == "Strength" && <Strength />}
                  {selected == "Dexterity" && <Dexterity />}
                  {selected == "Vitality" && <Vitality />}
                  {selected == "Intelligence" && <Intelligence />}
                  {selected == "Wisdom" && <Wisdom />}
                  {selected == "Charisma" && <Charisma />}
                </div>
                <div className="sm:w-1/3">
                  <VerticalKeyboardControl
                    buttonsData={upgradeMenu}
                    onSelected={setSelected}
                    onEnterAction={true}
                  />
                </div>
              </>
            ) : (
              <>
                <div className="sm:w-1/3">
                  <VerticalKeyboardControl
                    buttonsData={upgradeMenu}
                    onSelected={setSelected}
                    onEnterAction={true}
                  />
                </div>
                <div className="flex sm:w-2/3 items-center justify-center">
                  {selected == "Strength" && <Strength />}
                  {selected == "Dexterity" && <Dexterity />}
                  {selected == "Vitality" && <Vitality />}
                  {selected == "Intelligence" && <Intelligence />}
                  {selected == "Wisdom" && <Wisdom />}
                  {selected == "Charisma" && <Charisma />}
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
