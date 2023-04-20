import { useState, useEffect } from "react";
import HealthSlider from "./HealthSlider";
import { Button } from "./Button";
import { useContracts } from "../hooks/useContracts";
import { useAdventurer } from "../context/AdventurerProvider";
import { useTransactionCart } from "../context/TransactionCartProvider";
import { useTransactionManager } from "@starknet-react/core";
import { NullAdventurer } from "../types";

interface PurchaseHealthProps {
  isActive: boolean;
  onEscape: () => void;
}

const PurchaseHealth = ({ isActive, onEscape }: PurchaseHealthProps) => {
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

  const handlePurchaseHealth = async () => {
    addToCalls(purchaseHealthTx);
    await writeAsync().then((tx: any) => {
      addTransaction({
        hash: tx.transaction_hash,
        metadata: { test: true },
      });
    });
  };

  const handleKeyDown = (event: KeyboardEvent) => {
    switch (event.key) {
      case "ArrowRight":
        setHealthAmount((prev) => {
          const newAmount = Math.min(prev + 1, 10);
          return newAmount;
        });
        break;
      case "ArrowLeft":
        setHealthAmount((prev) => {
          const newAmount = Math.max(prev - 1, 1);
          return newAmount;
        });
        break;
      case "Enter":
        handlePurchaseHealth();
        break;
    }
  };

  useEffect(() => {
    if (isActive) {
      window.addEventListener("keydown", handleKeyDown);
    } else {
      window.removeEventListener("keydown", handleKeyDown);
    }
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isActive, healthAmount]);

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
          handlePurchaseHealth();
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
