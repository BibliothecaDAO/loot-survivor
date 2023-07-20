import React from "react";
import { Button } from "../buttons/Button";

interface SliderProps {
  purchaseAmount: number;
  setPurchaseAmount: (health: number) => void;
}

const HealthSlider: React.FC<SliderProps> = ({
  purchaseAmount,
  setPurchaseAmount,
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
      <Button size={"xs"} onClick={handleDecrement}>
        -
      </Button>
      <span className="text-xl p-2">{purchaseAmount}</span>
      <Button size={"xs"} onClick={handleIncrement}>
        +
      </Button>
    </div>
  );
};

export default HealthSlider;
