import { ReactElement, useState, useEffect } from "react";
import { useContracts } from "../hooks/useContracts";
import { getKeyFromValue } from "../lib/utils";
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

/**
 * @container
 * @description Provides the upgrade screen for the adventurer.
 */
const Upgrade = () => {
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
      value: "Strength",
      action: async () => setSelected("Strength"),
      disabled: loading,
    },
    {
      id: 2,
      label: `Dexterity - ${adventurer?.dexterity}`,
      value: "Dexterity",
      action: async () => setSelected("Dexterity"),
      disabled: loading,
    },
    {
      id: 3,
      label: `Vitality - ${adventurer?.vitality}`,
      value: "Vitality",
      action: async () => setSelected("Vitality"),
      disabled: loading,
    },
    {
      id: 4,
      label: `Intelligence - ${adventurer?.intelligence}`,
      value: "Intelligence",
      action: async () => setSelected("Intelligence"),
      disabled: loading,
    },
    {
      id: 5,
      label: `Wisdom - ${adventurer?.wisdom}`,
      value: "Wisdom",
      action: async () => setSelected("Wisdom"),
      disabled: loading,
    },
    {
      id: 6,
      label: `Charisma - ${adventurer?.charisma}`,
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
        adventurer?.id ?? "",
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
    <div className="flex flex-col items-center">
      <p className="sm:text-[28px] text-center">
        Strength increases attack damage by 10%
      </p>
      <Button onClick={() => handleUpgradeTx("Strength")}>
        Upgrade Strength
      </Button>
    </div>
  );
  const Dexterity = (): ReactElement => (
    <div className="flex flex-col items-center">
      <p className="sm:text-[28px] text-center">
        Dexterity increases chance of fleeing Beasts
      </p>
      <Button onClick={() => handleUpgradeTx("Dexterity")}>
        Upgrade Dexterity
      </Button>
    </div>
  );
  const Vitality = (): ReactElement => (
    <div className="flex flex-col items-center">
      <p className="sm:text-[28px] text-center">
        Vitality increases current and max health each by 20hp
      </p>
      <Button onClick={() => handleUpgradeTx("Vitality")}>
        Upgrade Vitality
      </Button>
    </div>
  );
  const Intelligence = (): ReactElement => (
    <div className="flex flex-col items-center">
      <p className="sm:text-[28px] text-center">
        Intelligence increases chance of avoiding Obstacles
      </p>
      <Button onClick={() => handleUpgradeTx("Intelligence")}>
        Upgrade Intelligence
      </Button>
    </div>
  );
  const Wisdom = (): ReactElement => (
    <div className="flex flex-col items-center">
      <p className="sm:text-[28px] text-center">
        Wisdom increases chance of avoiding a Beast ambush
      </p>
      <Button onClick={() => handleUpgradeTx("Wisdom")}>Upgrade Wisdom</Button>
    </div>
  );
  const Charisma = (): ReactElement => (
    <div className="flex flex-col items-center">
      <p className="sm:text-[30px] text-center">
        Charisma provides discounts on the marketplace and potions
      </p>
      <Button onClick={() => handleUpgradeTx("Charisma")}>
        Upgrade Charisma
      </Button>
    </div>
  );

  useEffect(() => {
    if (!(statUpgrades > 0)) {
      setScreen("actions");
    }
  }, [statUpgrades]);

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  return (
    <div className="flex flex-col sm:flex-row">
      <div className="w-1/3 mr-5 hidden sm:block">
        <Info adventurer={adventurer} />
      </div>
      <div className="w-2/3 m-auto">
        <div className="flex flex-col">
          <p className="mx-auto items-center justify-center text-center text-lg animate-pulse mb-10">
            You are now level {adventurer?.level}, please select upgrade!
          </p>
          <div className="flex flex-col gap-5 sm:gap-0 sm:flex-row w-full">
            {isMobileDevice ? (
              <>
                <div className="flex sm:w-2/3 items-center justify-center">
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
};

export default Upgrade;
