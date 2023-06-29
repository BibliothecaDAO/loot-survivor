import { useState, useEffect } from "react";
import HealthSlider from "./HealthSlider";
import { Button } from "../buttons/Button";
import { useContracts } from "../../hooks/useContracts";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import useTransactionCartStore from "../../hooks/useTransactionCartStore";

interface PurchaseHealthProps {
  isActive: boolean;
  onEscape: () => void;
}

const PurchaseHealth = ({ isActive, onEscape }: PurchaseHealthProps) => {
  const [healthAmount, setHealthAmount] = useState(1);
  const { gameContract } = useContracts();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);

  const purchaseHealthTx = {
    contractAddress: gameContract?.address ?? "",
    entrypoint: "purchase_health",
    calldata: [adventurer?.id ?? "", healthAmount],
    metadata: `Purchasing ${healthAmount * 10} health`,
  };

  let purchaseGoldAmount;

  if (
    adventurer &&
    (adventurer?.level ?? 0) - (adventurer?.charisma ?? 0) <= 3
  ) {
    purchaseGoldAmount = healthAmount * 3;
  } else {
    let discount =
      (adventurer && (adventurer?.level ?? 0) - (adventurer?.charisma ?? 0)) ||
      0;
    purchaseGoldAmount = healthAmount * (3 * discount);
  }

  const hasBalance =
    adventurer?.gold && adventurer?.gold >= purchaseGoldAmount ? true : false;

  const handlePurchaseHealth = async () => {
    addToCalls(purchaseHealthTx);
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
    <div className="flex flex-col gap-5 p-5 sm:p-0 m-auto">
      <HealthSlider
        purchaseAmount={healthAmount}
        setPurchaseAmount={setHealthAmount}
      />
      <p>
        Health potions to purchase: <strong>{healthAmount}</strong>, This will
        cost you <strong>{purchaseGoldAmount}</strong> gold! You can only buy up
        to Max Health! 1 Potion = 10 Health
      </p>
      <Button
        disabled={!hasBalance}
        onClick={async () => {
          handlePurchaseHealth();
        }}
      >
        Purchase Health
      </Button>
      {!hasBalance && (
        <p className="m-auto text-red-600">Not enough gold to purchase!</p>
      )}
    </div>
  );
};

export default PurchaseHealth;
