import { useState } from "react";
import { Button } from "./Button";
import { useContracts } from "../hooks/useContracts";
import { useTransactionCart } from "../context/TransactionCartProvider";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurerProps } from "../types";
import {
  useTransaction,
  useTransactions,
  useTransactionManager,
  useWaitForTransaction,
} from "@starknet-react/core";
import Image from "next/image";
import VerticalKeyboardControl from "./VerticalMenu";
import HealthSlider from "./HealthSlider";
import PurchaseHealth from "./PurchaseHealth";
import Info from "./Info";
import Discovery from "./Discovery";

export default function Actions() {
  const [loading, setLoading] = useState(false);
  const { writeAsync, addToCalls, calls } = useTransactionCart();
  const { adventurerContract } = useContracts();
  const { adventurer, handleUpdateAdventurer } = useAdventurer();
  const { hashes, addTransaction } = useTransactionManager();
  const [selected, setSelected] = useState<String>("");
  const [potionNumber, setPotionNumber] = useState(0);

  const formatAdventurer = adventurer ? adventurer : NullAdventurerProps;

  const exploreTx = {
    contractAddress: adventurerContract?.address,
    selector: "explore",
    calldata: [adventurer?.adventurer?.id, "0"],
  };

  const handlePurchase = (health: number) => {
    console.log(`Purchased ${health} health.`);
  };

  const buttonsData = [
    {
      id: 1,
      label: "Explore",
      value: "explore",
      action: async () => {
        {
          const tx = await adventurerContract?.invoke("explore", [
            [adventurer?.adventurer?.id, "0"],
          ]);
          if (tx) {
            addTransaction({
              hash: tx?.transaction_hash,
              metadata: { method: "explore" },
            });
          }
          // addToCalls(exploreTx);
          // await writeAsync().then((tx) => {
          // addTransaction({
          //   hash: tx.transaction_hash,
          //   metadata: { method: "explore" },
          // });
          // });
        }
      },
    },
    {
      id: 2,
      label: "Purchase Health",
      value: "purchase health",
      action: async () => await writeAsync(),
    },
  ];

  return (
    <div className="flex flex-row mt-5">
      {!loading ? (
        <div className="w-1/3">
          <Info adventurer={adventurer?.adventurer} />
        </div>
      ) : null}
      <div className="w-1/3 my-auto">
        <VerticalKeyboardControl
          buttonsData={buttonsData}
          onSelected={(value) => setSelected(value)}
          onEnterAction={true}
        />
      </div>

      <div className="flex flex-col w-1/3 bg-terminal-black m-2 p-2">
        {selected == "explore" && <Discovery />}
        {selected == "purchase health" && <PurchaseHealth />}
      </div>
    </div>
  );
}
