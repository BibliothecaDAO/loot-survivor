import { useState } from "react";
import HealthSlider from "./HealthSlider";
import { Button } from "./Button";
import { useContracts } from "../hooks/useContracts";
import { useAdventurer } from "../context/AdventurerProvider";
import { useTransactionCart } from "../context/TransactionCartProvider";
import { useTransactionManager } from "@starknet-react/core";
import { NullAdventurer } from "../types";

const PurchaseHealth = () => {
  const [healthAmount, setHealthAmount] = useState(1);
  const { adventurerContract } = useContracts();
  const { adventurer, handleUpdateAdventurer } = useAdventurer();
  const { writeAsync, addToCalls } = useTransactionCart();
  const { addTransaction } = useTransactionManager();

  const formatAdventurer = adventurer ? adventurer.adventurer : NullAdventurer;
  const purchaseHealthTx = {
    contractAddress: adventurerContract?.address,
    selector: "purchase_health",
    calldata: [formatAdventurer?.id, "0", healthAmount],
  };
  const purchaseGoldAmount = healthAmount * 5;
  const hasBalance =
    formatAdventurer?.gold && formatAdventurer?.gold <= purchaseGoldAmount
      ? true
      : false;
  return (
    <div className="flex flex-col m-auto gap-5">
      <HealthSlider
        purchaseAmount={healthAmount}
        setPurchaseAmount={setHealthAmount}
      />
      <p>
        Health potions to purchase: <strong>{healthAmount}</strong>, This will
        cost you <strong>{purchaseGoldAmount}</strong> gold!
      </p>
      <Button
        disabled={hasBalance}
        onClick={async () => {
          addToCalls(purchaseHealthTx);
          await writeAsync().then((tx: any) => {
            addTransaction({
              hash: tx.transaction_hash,
              metadata: { test: true },
            });
          });
        }}
      >
        Purchase Health
      </Button>
      {hasBalance && (
        <p className="m-auto text-red-600">Not enough gold to purchase!</p>
      )}
    </div>
  );
};

export default PurchaseHealth;
