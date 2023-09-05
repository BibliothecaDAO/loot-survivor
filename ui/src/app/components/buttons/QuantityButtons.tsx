import React from "react";
import { Button } from "./Button";

interface ButtonProps {
  amount: number;
  max: number;
  min: number;
  setAmount: (value: number) => void;
}

const HealthButtons: React.FC<ButtonProps> = ({
  amount,
  max,
  min,
  setAmount,
}) => {
  const handleIncrement = () => {
    if (amount < max) {
      setAmount(amount + 1);
    }
  };

  const handleDecrement = () => {
    if (amount > min) {
      setAmount(amount - 1);
    }
  };

  return (
    <div>
      <Button
        className="text-base sm:text-2xl"
        size={"sm"}
        onClick={handleDecrement}
        disabled={amount <= min}
      >
        -
      </Button>
      <span className="text-xl p-2">{amount}</span>
      <Button
        className="text-2xl mr-1"
        size={"sm"}
        onClick={handleIncrement}
        disabled={amount >= max}
      >
        +
      </Button>
    </div>
  );
};

export default HealthButtons;
