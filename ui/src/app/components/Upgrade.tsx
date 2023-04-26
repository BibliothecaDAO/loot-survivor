import { ReactElement, ReactNode, useState } from "react";
import { useContracts } from "../hooks/useContracts";
import { useTransactionCart } from "../context/TransactionCartProvider";
import { useAdventurer } from "../context/AdventurerProvider";
import { getKeyFromValue } from "../lib/utils";
import { GameData } from "./GameData";
import VerticalKeyboardControl from "./VerticalMenu";
import {
  useTransactionManager,
  useWaitForTransaction,
} from "@starknet-react/core";

const Upgrade = () => {
  const { adventurerContract } = useContracts();
  const { adventurer } = useAdventurer();
  const { addTransaction } = useTransactionManager();
  const { handleSubmitCalls, addToCalls } = useTransactionCart();
  const [selected, setSelected] = useState("");
  const [hash, setHash] = useState("");
  const { data, status, isLoading, error } = useWaitForTransaction({
    hash: hash,
    watch: true,
  });

  const gameData = new GameData();

  const upgradeMenu = [
    {
      id: 1,
      label: `Strength - ${adventurer?.adventurer?.strength}`,
      value: "Strength",
      action: async () => handleUpgradeTx("Strength"),
    },
    {
      id: 2,
      label: `Dexterity - ${adventurer?.adventurer?.dexterity}`,
      value: "Dexterity",
      action: async () => handleUpgradeTx("Dexterity"),
    },
    {
      id: 3,
      label: `Vitality - ${adventurer?.adventurer?.vitality}`,
      value: "Vitality",
      action: async () => handleUpgradeTx("Vitality"),
    },
    {
      id: 4,
      label: `Intelligence - ${adventurer?.adventurer?.intelligence}`,
      value: "Intelligence",
      action: async () => handleUpgradeTx("Intelligence"),
    },
    {
      id: 5,
      label: `Wisdom - ${adventurer?.adventurer?.wisdom}`,
      value: "Wisdom",
      action: async () => handleUpgradeTx("Wisdom"),
    },
    {
      id: 6,
      label: `Charisma - ${adventurer?.adventurer?.charisma}`,
      value: "Charisma",
      action: async () => handleUpgradeTx("Charisma"),
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

  const handleUpgradeTx = async (selected: any) => {
    console.log(`Upgrading ${selected}`);
    addToCalls(upgradeTx);
    handleSubmitCalls().then((tx: any) => {
      setHash(tx.transaction_hash);
      addTransaction({
        hash: tx.transaction_hash,
        metadata: {
          method: "Upgrade Stat",
          description: `Upgrading ${selected}`,
        },
      });
    });
  };

  const Strength = (): ReactElement => (
    <p className="text-[28px]">Strength increases attack damage by 10%</p>
  );
  const Dexterity = (): ReactElement => (
    <p className="text-[28px]">Dexterity increases chance of fleeing</p>
  );
  const Vitality = (): ReactElement => (
    <p className="text-[28px]">
      Vitality increases health by 20hp, including max health
    </p>
  );
  const Intelligence = (): ReactElement => (
    <p className="text-[28px]">
      Intelligence increases chance of avoiding Obstacles
    </p>
  );
  const Wisdom = (): ReactElement => (
    <p className="text-[28px]">
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
      {hash ? (
        <div className="m-auto">
          {(data?.status == "RECEIVED" || data?.status == "PENDING") && (
            <div className="loading-ellipsis">Loading</div>
          )}
          <div className="flex flex-col">Hash: {hash}</div>
          {data && <div>Status: {data.status}</div>}
        </div>
      ) : (
        <>
          <p className="mx-auto items-center text-[60px] animate-pulse">
            You are now level {adventurer?.adventurer?.level}, please select
            upgrade!
          </p>
          <div className="flex flex-row">
            <div className="w-1/2">
              <VerticalKeyboardControl
                buttonsData={upgradeMenu}
                onSelected={setSelected}
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
        </>
      )}
    </div>
  );
};

export default Upgrade;
