import { ReactElement, useState, useEffect } from "react";
import { useContracts } from "../hooks/useContracts";
import { getKeyFromValue } from "../lib/utils";
import { GameData } from "./GameData";
import VerticalKeyboardControl from "./VerticalMenu";
import { useTransactionManager, useContractWrite } from "@starknet-react/core";
import { useQuery } from "@apollo/client";
import { getAdventurerById } from "../hooks/graphql/queries";
import useLoadingStore from "../hooks/useLoadingStore";
import useAdventurerStore from "../hooks/useAdventurerStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import useUIStore from "../hooks/useUIStore";

const Upgrade = () => {
  const { adventurerContract } = useContracts();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const startLoading = useLoadingStore((state) => state.startLoading);
  const setTxHash = useLoadingStore((state) => state.setTxHash);
  const loading = useLoadingStore((state) => state.loading);
  const { addTransaction } = useTransactionManager();
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const { writeAsync } = useContractWrite({ calls });
  const setScreen = useUIStore((state) => state.setScreen);
  const [selected, setSelected] = useState("");
  const upgrade = adventurer?.upgrading;

  const gameData = new GameData();

  const upgradeMenu = [
    {
      id: 1,
      label: `Strength - ${adventurer?.strength}`,
      value: "Strength",
      action: async () => handleUpgradeTx("Strength"),
      disabled: loading,
    },
    {
      id: 2,
      label: `Dexterity - ${adventurer?.dexterity}`,
      value: "Dexterity",
      action: async () => handleUpgradeTx("Dexterity"),
      disabled: loading,
    },
    {
      id: 3,
      label: `Vitality - ${adventurer?.vitality}`,
      value: "Vitality",
      action: async () => handleUpgradeTx("Vitality"),
      disabled: loading,
    },
    {
      id: 4,
      label: `Intelligence - ${adventurer?.intelligence}`,
      value: "Intelligence",
      action: async () => handleUpgradeTx("Intelligence"),
      disabled: loading,
    },
    {
      id: 5,
      label: `Wisdom - ${adventurer?.wisdom}`,
      value: "Wisdom",
      action: async () => handleUpgradeTx("Wisdom"),
      disabled: loading,
    },
    {
      id: 6,
      label: `Charisma - ${adventurer?.charisma}`,
      value: "Charisma",
      action: async () => handleUpgradeTx("Charisma"),
      disabled: loading,
    },
  ];

  const handleUpgradeTx = async (selected: any) => {
    const upgradeTx = {
      contractAddress: adventurerContract?.address ?? "",
      entrypoint: "upgrade_stat",
      calldata: [
        adventurer?.id ?? "",
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
    <p className="sm:text-[28px]">Strength increases attack damage by 10%</p>
  );
  const Dexterity = (): ReactElement => (
    <p className="sm:text-[28px]">Dexterity increases chance of fleeing</p>
  );
  const Vitality = (): ReactElement => (
    <p className="sm:text-[28px]">
      Vitality increases current and max health each by 20hp
    </p>
  );
  const Intelligence = (): ReactElement => (
    <p className="sm:text-[28px]">
      Intelligence increases chance of avoiding Obstacles
    </p>
  );
  const Wisdom = (): ReactElement => (
    <p className="sm:text-[28px]">
      Wisdom increases chance of avoiding a Beast ambush
    </p>
  );
  const Charisma = (): ReactElement => (
    <p className="sm:text-[30px]">
      Charisma provides discounts on the marketplace
    </p>
  );

  useEffect(() => {
    if (!upgrade) {
      setScreen("actions");
    }
  }, [upgrade]);

  return (
    <div className="flex flex-col gap-10 w-full mt-[100px]">
      <p className="mx-auto items-center sm:text-[60px] animate-pulse">
        You are now level {adventurer?.level}, please select upgrade!
      </p>
      <div className="flex flex-row">
        <div className="w-1/2">
          <VerticalKeyboardControl
            buttonsData={upgradeMenu}
            onSelected={setSelected}
            onEnterAction={true}
          />
        </div>
        <div className="flex items-center justify-center w-1/2">
          {selected == "Strength" && <Strength />}
          {selected == "Dexterity" && <Dexterity />}
          {selected == "Vitality" && <Vitality />}
          {selected == "Intelligence" && <Intelligence />}
          {selected == "Wisdom" && <Wisdom />}
          {selected == "Charisma" && <Charisma />}
        </div>
      </div>
    </div>
  );
};

export default Upgrade;
