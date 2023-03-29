import React, { useEffect, useState, useRef } from "react";
import { Button } from "./Button";

interface ButtonData {
  id: number;
  label: string;
  value: any;
}

interface HorizontalKeyboardControlProps {
  buttonsData: ButtonData[];
  onButtonClick: (value: any) => void;
}

const HorizontalKeyboardControl: React.FC<HorizontalKeyboardControlProps> = ({
  buttonsData,
  onButtonClick,
}) => {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);

  useEffect(() => {
    onButtonClick(buttonsData[selectedIndex].value);
  }, [selectedIndex]);

  const handleKeyDown = (event: KeyboardEvent) => {
    switch (event.key) {
      case "ArrowLeft":
        setSelectedIndex((prev) => {
          const newIndex = Math.max(prev - 1, 0);
          return newIndex;
        });
        break;
      case "ArrowRight":
        setSelectedIndex((prev) => {
          const newIndex = Math.min(prev + 1, buttonsData.length - 1);
          return newIndex;
        });
        break;
    }
  };

  useEffect(() => {
    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [selectedIndex]);

  return (
    <div>
      {buttonsData.map((buttonData, index) => (
        <Button
          key={buttonData.id}
          ref={(ref) => (buttonRefs.current[index] = ref)}
          variant={selectedIndex === index ? "default" : "outline"}
          onClick={() => onButtonClick(buttonData.value)}
        >
          {buttonData.label}
        </Button>
      ))}
    </div>
  );
};

export default HorizontalKeyboardControl;
