import React, { useState } from "react";

interface SliderProps {
  onPurchase: (health: number) => void;
}

const HealthSlider: React.FC<SliderProps> = ({ onPurchase }) => {
  const [health, setHealth] = useState(1);

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const value = parseInt(event.target.value, 10);
    setHealth(value);
  };

  const purchaseHealth = () => {
    onPurchase(health);
  };

  return (
    <div className="health-slider">
      <input
        type="range"
        min="1"
        max="10"
        value={health}
        onChange={handleChange}
        className="slider"
      />
      <p>
        Health to purchase: <strong>{health}</strong>
      </p>
      <button onClick={purchaseHealth}>Purchase Health</button>
    </div>
  );
};

export default HealthSlider;
