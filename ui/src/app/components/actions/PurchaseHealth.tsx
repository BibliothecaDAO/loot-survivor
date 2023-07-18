import { useState, useEffect, useCallback } from "react";
import HealthSlider from "./HealthSlider";
import { Button } from "../buttons/Button";
import { useContracts } from "../../hooks/useContracts";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import useTransactionCartStore from "../../hooks/useTransactionCartStore";
import { CoinIcon } from "../icons/Icons";

interface PurchaseHealthProps {
  upgradeTotalCost: number;
}

const PurchaseHealth = ({ upgradeTotalCost }: PurchaseHealthProps) =>
  // { isActive, onEscape }: PurchaseHealthProps
  {
    const [potionAmount, setHealthAmount] = useState(1);
    const { gameContract } = useContracts();
    const adventurer = useAdventurerStore((state) => state.adventurer);
    const addToCalls = useTransactionCartStore((state) => state.addToCalls);

    const purchaseHealthTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "buy_potions",
      calldata: [
        adventurer?.id?.toString() ?? "",
        "0",
        potionAmount.toString(),
      ],
      metadata: `Purchasing ${potionAmount * 10} health`,
    };

    const purchaseGoldAmount = Math.max(
      potionAmount * (adventurer?.level ?? 0) - 2 * (adventurer?.charisma ?? 0),
      2
    );

    const hasBalance =
      adventurer?.gold &&
      adventurer?.gold - upgradeTotalCost >= purchaseGoldAmount
        ? true
        : false;

    const handlePurchaseHealth = async () => {
      addToCalls(purchaseHealthTx);
    };

    const handleKeyDown = useCallback(
      (event: KeyboardEvent) => {
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
      },
      [potionAmount]
    );

    const maxHealth = 100 + (adventurer?.vitality ?? 0) * 20;

    const calculatedNewHealth = (adventurer?.health ?? 0) + potionAmount * 10;

    return (
      <div className="flex flex-col gap-5 p-5 sm:p-0 md:p-2">
        <HealthSlider
          purchaseAmount={potionAmount}
          setPurchaseAmount={setHealthAmount}
        />
        <span className="flex flex-row gap-2 text-lg">
          <p>
            Purchasing{" "}
            <strong className="text-terminal-yellow">{potionAmount}</strong>{" "}
            potion(s) for{" "}
          </p>
          <span className="flex flex-row">
            <CoinIcon className="w-5 h-5 fill-current text-terminal-yellow" />
            <p className="text-terminal-yellow">{purchaseGoldAmount}</p>
          </span>
        </span>
        <p> You can only buy up to Max Health! 1 Potion = 10 Health</p>
        <Button
          disabled={
            !hasBalance ||
            adventurer?.health == maxHealth ||
            calculatedNewHealth - maxHealth > 10
          }
          onClick={async () => {
            handlePurchaseHealth();
          }}
        >
          {adventurer?.health == maxHealth
            ? "Max Health Reached"
            : calculatedNewHealth - maxHealth > 10
            ? "Purchase Over Max Health"
            : "Purchase Health"}
        </Button>
        {!hasBalance && (
          <p className="m-auto text-red-600">Not enough gold to purchase!</p>
        )}
      </div>
    );
  };

export default PurchaseHealth;
