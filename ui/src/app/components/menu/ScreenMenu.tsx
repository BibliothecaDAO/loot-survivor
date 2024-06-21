import React, { useEffect, useState, useRef, useCallback } from "react";
import { Button } from "@/app/components/buttons/Button";
import { soundSelector, useUiSounds } from "@/app/hooks/useUiSound";
import { Menu } from "@/app/types";
import useUIStore from "@/app/hooks/useUIStore";

export interface ButtonData {
  id: number;
  label: string;
  value: string;
  disabled?: boolean;
}

interface HorizontalKeyboardControlProps {
  buttonsData: Menu[];
  disabled?: boolean[];
  onButtonClick: (value: any) => void;
}

const HorizontalKeyboardControl: React.FC<HorizontalKeyboardControlProps> = ({
  buttonsData,
  onButtonClick,
  disabled,
}) => {
  const { play } = useUiSounds(soundSelector.click);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const screen = useUIStore((state) => state.screen);

  useEffect(() => {
    onButtonClick(buttonsData[selectedIndex]?.screen);
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
      // Adding a null check for e.target
      if (!event.target) return;
      const target = event.target as HTMLElement;
      // Check if the target is an input element
      if (target.tagName.toLowerCase() === "input") {
        // If it's an input element, allow default behavior (moving cursor within the input)
        return;
      }

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
    <div className="flex justify-between sm:justify-start w-full">
      {buttonsData.map((buttonData, index) => (
        <Button
          className="px-2.5 sm:px-3"
          key={buttonData.id}
          ref={(ref) => (buttonRefs.current[index] = ref)}
          variant={buttonData.screen === screen ? "default" : "outline"}
          onClick={() => {
            setSelectedIndex(index);
            onButtonClick(buttonData.screen);
          }}
          disabled={disabled ? disabled[index] : false}
        >
          {buttonData.label}
        </Button>
      ))}
    </div>
  );
};

export default HorizontalKeyboardControl;
