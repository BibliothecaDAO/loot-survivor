import { ReactElement, ReactNode, useState } from "react";
import { useContracts } from "../hooks/useContracts";
import { useWriteContract } from "../hooks/useWriteContract";
import { useAdventurer } from "../context/AdventurerProvider";
import { getKeyFromValue } from "../lib/utils";
import { GameData } from "./GameData";
import VerticalKeyboardControl from "./VerticalMenu";
import { useTransactionManager } from "@starknet-react/core";

const Upgrade = () => {
  const { adventurerContract } = useContracts();
  const { writeAsync, addToCalls } = useWriteContract();
  const { adventurer } = useAdventurer();
  const { addTransaction } = useTransactionManager();
  const [selected, setSelected] = useState("");

  const gameData = new GameData();

  const upgradeMenu = [
    {
      id: 1,
      label: "Strength",
      value: "Strength",
      action: async () => handleUpgradeTx(),
    },
    {
      id: 2,
      label: "Dexterity",
      value: "Dexterity",
      action: async () => handleUpgradeTx(),
    },
    {
      id: 3,
      label: "Vitality",
      value: "Vitality",
      action: async () => handleUpgradeTx(),
    },
    {
      id: 4,
      label: "Intelligence",
      value: "Intelligence",
      action: async () => handleUpgradeTx(),
    },
    {
      id: 5,
      label: "Wisdom",
      value: "Wisdom",
      action: async () => handleUpgradeTx(),
    },
    {
      id: 6,
      label: "Charisma",
      value: "Charisma",
      action: async () => handleUpgradeTx(),
    },
  ];

  const upgradeTx = {
    contractAddress: adventurerContract?.address,
    selector: "upgrade_stat",
    calldata: [
      adventurer?.adventurer?.id,
      "0",
      getKeyFromValue(gameData.STATS, selected),
    ],
  };

  const handleUpgradeTx = async () => {
    addToCalls(upgradeTx);
    await writeAsync().then((tx) => {
      addTransaction({
        hash: tx.transaction_hash,
        metadata: { test: true },
      });
    });
  };

  const Strength = (): ReactElement => (
    <p className="text-[30px]">Strength increases attack damage by 10%</p>
  );
  const Dexterity = (): ReactElement => (
    <p className="text-[30px]">Dexterity increases chance of fleeing</p>
  );
  const Vitality = (): ReactElement => (
    <p className="text-[30px]">
      Vitality increases health by 20hp, including max health
    </p>
  );
  const Intelligence = (): ReactElement => (
    <p className="text-[30px]">
      Intelligence increases chance of avoiding Obstacles
    </p>
  );
  const Wisdom = (): ReactElement => (
    <p className="text-[30px]">
      Wisdom increases chance of avoiding a Beast ambush
    </p>
  );
  const Charisma = (): ReactElement => (
    <p className="text-[30px]">
      Luck increases chance of hitting critical damage
    </p>
  );

  return (
    <div className="flex flex-col gap-10 w-full mt-[100px]">
      <p className="mx-auto items-center text-[80px] animate-pulse">
        Please select upgrade!
      </p>
      <div className="flex flex-row">
        <div className="w-1/2">
          <VerticalKeyboardControl
            buttonsData={upgradeMenu}
            onSelected={(value) => setSelected(value)}
            onEnterAction={true}
          />
        </div>
        <div className="flex items-center justify-center w-1/2 bg-black border">
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
