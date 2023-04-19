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
  useWaitForTransaction,
} from "@starknet-react/core";
import Image from "next/image";
import KeyboardControl, { ButtonData } from "./KeyboardControls";
import HealthSlider from "./HealthSlider";
import Info from "./Info";
import Discovery from "./Discovery";

export default function Actions() {
  const [loading, setLoading] = useState(false);
  const { writeAsync, addToCalls, calls } = useWriteContract();
  const { adventurerContract } = useContracts();
  const { adventurer, handleUpdateAdventurer } = useAdventurer();
  const [hash, setHash] = useState<string | undefined>(undefined);
  const { hashes, addTransaction } = useTransactionManager();
  const { data, isLoading, error } = useWaitForTransaction({
    hash,
    watch: true,
  });
  const [selected, setSelected] = useState<String>("");

  const formatAdventurer = adventurer ? adventurer : NullAdventurerProps;

  const explore = {
    contractAddress: adventurerContract?.address,
    selector: "explore",
    calldata: [adventurer?.adventurer?.id || 0, "0"],
  };

  const handlePurchase = (health: number) => {
    console.log(`Purchased ${health} health.`);
  };

  const buttonsData: ButtonData[] = [
    {
      id: 1,
      label: "Explore",
      action: async () => {
        {
          addToCalls(explore);
          console.log(explore);
          console.log(calls);
          await writeAsync().then((tx) => {
            addTransaction({
              hash: tx.transaction_hash,
              metadata: { test: true },
            });
            setHash(tx.transaction_hash);
          });
        }
      },
    },
    {
      id: 2,
      label: "Purchase Health",
      action: async () => await writeAsync(),
    },
  ];

  return (
    <div className="flex flex-row mt-5">
      {!loading ? (
        <div className="w-1/4">
          <Info />
        </div>
      ) : null}
      <div className="w-1/4 my-auto">
        <KeyboardControl buttonsData={buttonsData} />
      </div>
      {/* <p>Health Purchase</p>
        <HealthSlider onPurchase={handlePurchase} /> */}

      <div className="flex flex-col w-1/2 bg-terminal-black m-2 p-2">
        {/* {selected == <Discovery />} */}
        <div></div>
      </div>
    </div>
  );
}
