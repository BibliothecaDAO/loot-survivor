import React from "react";

interface SliderProps {
  purchaseAmount: number;
  setPurchaseAmount: (health: number) => void;
}

const HealthSlider: React.FC<SliderProps> = ({
  purchaseAmount,
  setPurchaseAmount,
}) => {
  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const value = parseInt(event.target.value, 10);
    setPurchaseAmount(value);
  };

  return (
    <input
      type="range"
      min="1"
      max="10"
      value={purchaseAmount}
      onChange={handleChange}
      className="slider bg-terminal-green"
    />
  );
};

export default HealthSlider;
