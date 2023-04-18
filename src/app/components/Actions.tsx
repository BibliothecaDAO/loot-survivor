import { useState } from "react";
import { Button } from "./Button";
import { useContracts } from "../hooks/useContracts";
import { useWriteContract } from "../hooks/useWriteContract";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurerProps } from "../types";
import {
  useTransaction,
  useTransactions,
  useTransactionManager,
} from "@starknet-react/core";
import Image from "next/image";
import KeyboardControl, { ButtonData } from "./KeyboardControls";
import HealthSlider from "./HealthSlider";
import Info from "./Info";
import TransactionBar from "./TransactionBar";

export default function Actions() {
  const [loading, setLoading] = useState(false);

  const { writeAsync, addToCalls, calls } = useWriteContract();
  const { adventurerContract } = useContracts();
  const { adventurer, handleUpdateAdventurer } = useAdventurer();

  const formatAdventurer = adventurer ? adventurer : NullAdventurerProps;

  // const [hash, setHash] = useState<string | undefined>(undefined);

  // const explore = {
  //   contractAddress: lootContract?.address,
  //   selector: "explore",
  //   calldata: [formatAddress],
  // };

  const buttonsData: ButtonData[] = [
    {
      id: 1,
      label: "Explore",
      action: async () => {
        // addToCalls(explore);
        // console.log(calls);
        // await writeAsync().then((tx) => setHash(tx.transaction_hash));
      },
    },
    {
      id: 2,
      label: "Swap Item",
      action: async () => await writeAsync(),
    },
    {
      id: 3,
      label: "Purchase Health",
      action: async () => await writeAsync(),
    },
  ];

  const handlePurchase = (health: number) => {
    console.log(`Purchased ${health} health.`);
  };

  return (
    <div className="flex flex-row mt-5">
      {!loading ? (
        <div className="w-1/4">
          <Info />
        </div>
      ) : null}
      <div className="w-1/4">
        <KeyboardControl buttonsData={buttonsData} />
      </div>
      {/* <p>Health Purchase</p>
        <HealthSlider onPurchase={handlePurchase} /> */}

      <div className="flex flex-col w-1/2 bg-terminal-black"></div>
    </div>
  );
}
