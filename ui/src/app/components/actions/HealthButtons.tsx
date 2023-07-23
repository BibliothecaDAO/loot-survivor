import React from "react";
import { Button } from "../buttons/Button";

interface ButtonProps {
  purchaseAmount: number;
  setPurchaseAmount: (health: number) => void;
  disabled: boolean;
}

const HealthSlider: React.FC<ButtonProps> = ({
  purchaseAmount,
  setPurchaseAmount,
  disabled,
}) => {
  const handleIncrement = () => {
    if (purchaseAmount < 10) {
      setPurchaseAmount(purchaseAmount + 1);
    }
  };

  const handleDecrement = () => {
    if (purchaseAmount > 1) {
      setPurchaseAmount(purchaseAmount - 1);
    }
  };

  return (
    <div>
      <Button
        className="text-base sm:text-2xl"
        size={"sm"}
        onClick={handleDecrement}
        disabled={purchaseAmount <= 1}
      >
        -
      </Button>
      <span className="text-xl p-2">{purchaseAmount}</span>
      <Button
        className="text-base text-2xl"
        size={"sm"}
        onClick={handleIncrement}
        disabled={disabled}
      >
        +
      </Button>
    </div>
  );
};

export default HealthSlider;
