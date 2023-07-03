import React, { useEffect, useState, useRef, useCallback } from "react";
import { Button } from "../buttons/Button";
import { soundSelector, useUiSounds } from "../../hooks/useUiSound";
import { Menu } from "../../types";
import useUIStore from "@/app/hooks/useUIStore";

export interface ButtonData {
  id: number;
  label: string;
  value: string;
  disabled?: boolean;
}

interface HorizontalKeyboardControlProps {
  buttonsData: Menu[];
  onButtonClick: (value: any) => void;
}

const HorizontalKeyboardControl: React.FC<HorizontalKeyboardControlProps> = ({
  buttonsData,
  onButtonClick,
}) => {
  const { play } = useUiSounds(soundSelector.click);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const screen = useUIStore((state) => state.screen);

  useEffect(() => {
    onButtonClick(buttonsData[selectedIndex].screen);
  }, [selectedIndex, buttonsData]);

  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      const getNextEnabledIndex = (currentIndex: number, direction: number) => {
        let newIndex = currentIndex + direction;

        while (
          newIndex >= 0 &&
          newIndex < buttonsData.length &&
          buttonsData[newIndex].disabled
        ) {
          newIndex += direction;
        }

        return newIndex;
      };

      switch (event.key) {
        case "ArrowLeft":
          play();
          setSelectedIndex((prev) => {
            const newIndex = getNextEnabledIndex(prev, -1);
            return newIndex < 0 ? prev : newIndex;
          });
          break;
        case "ArrowRight":
          play();
          setSelectedIndex((prev) => {
            const newIndex = getNextEnabledIndex(prev, 1);
            return newIndex >= buttonsData.length ? prev : newIndex;
          });
          break;
      }
    },
    [selectedIndex, buttonsData, play]
  );

  useEffect(() => {
    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [selectedIndex, handleKeyDown]);

  return (
    <div>
      {buttonsData.map((buttonData, index) => (
        <Button
          className="px-3"
          key={buttonData.id}
          ref={(ref) => (buttonRefs.current[index] = ref)}
          variant={buttonData.screen === screen ? "default" : "outline"}
          onClick={() => {
            setSelectedIndex(index);
            onButtonClick(buttonData.screen);
          }}
          disabled={buttonData.disabled}
        >
          {buttonData.label}
        </Button>
      ))}
    </div>
  );
};

export default HorizontalKeyboardControl;
