import React from "react";
import { Button } from "@/app/components/buttons/Button";

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
    <div className="text-xl">
      <Button
        size={"xs"}
        variant={"outline"}
        onClick={handleDecrement}
        disabled={amount <= min}
      >
        -
      </Button>
      <span className=" p-2">{amount}</span>
      <Button
        size={"sm"}
        variant={"outline"}
        onClick={handleIncrement}
        disabled={amount >= max}
      >
        +
      </Button>
    </div>
  );
};

export default HealthButtons;
