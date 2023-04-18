import React, { useEffect, useState, useRef } from "react";
import { Button } from "./Button";

interface ButtonData {
  id: number;
  label: string;
  value: any;
  action: () => void;
}

interface VerticalKeyboardControlProps {
  buttonsData: ButtonData[];
  onButtonClick: (value: any) => void;
  onEnterPress?: (value: any) => void;
}

const VerticalKeyboardControl: React.FC<VerticalKeyboardControlProps> = ({
  buttonsData,
  onButtonClick,
  onEnterPress,
}) => {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);

  useEffect(() => {
    onButtonClick(buttonsData[selectedIndex].value);
  }, [selectedIndex]);

  const handleKeyDown = (event: KeyboardEvent) => {
    switch (event.key) {
      case "ArrowDown":
        setSelectedIndex((prev) => {
          const newIndex = Math.min(prev + 1, buttonsData.length - 1);
          return newIndex;
        });
        break;
      case "ArrowUp":
        setSelectedIndex((prev) => {
          const newIndex = Math.max(prev - 1, 0);
          return newIndex;
        });
        break;
      case "Enter":
        if (onEnterPress) {
          buttonsData[selectedIndex].value();
        }
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
    <div className="flex flex-col w-full">
      {buttonsData.map((buttonData, index) => (
        <Button
          key={buttonData.id}
          ref={(ref) => (buttonRefs.current[index] = ref)}
          className={selectedIndex === index ? "animate-pulse" : ""}
          variant={selectedIndex === index ? "default" : "outline"}
          onClick={() => {
            setSelectedIndex(index);
            buttonData.action();
            onButtonClick(buttonData.value);
          }}
        >
          {buttonData.label}
        </Button>
      ))}
    </div>
  );
};

export default VerticalKeyboardControl;
