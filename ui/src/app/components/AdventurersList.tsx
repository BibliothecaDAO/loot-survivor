import { useState, useEffect, useRef } from "react";
import { Button } from "./Button";
import Info from "./Info";
import useAdventurerStore from "../hooks/useAdventurerStore";
import { ButtonData } from "./KeyboardControls";
import useLoadingStore from "../hooks/useLoadingStore";

export interface AdventurerListProps {
  isActive: boolean;
  onEscape: () => void;
  adventurers: any[];
}

export const AdventurersList = ({
  isActive,
  onEscape,
  adventurers,
}: AdventurerListProps) => {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);

  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);

  const buttonsData: ButtonData[] = [];
  for (let i = 0; i < adventurers.length; i++) {
    buttonsData.push({
      id: i + 1,
      label: `${adventurers[i].name} - ${adventurers[i].id}`,
      action: () =>
        setAdventurer({ adventurer: adventurers[i], image: undefined }),
    });
  }

  const handleKeyDown = (event: KeyboardEvent) => {
    switch (event.key) {
      case "ArrowUp":
        setSelectedIndex((prev) => Math.max(prev - 1, 0));
        break;
      case "ArrowDown":
        setSelectedIndex((prev) => Math.min(prev + 1, buttonsData.length - 1));
        break;
      case "Enter":
        buttonsData[selectedIndex].action();
        break;
      case "Escape":
        onEscape();
        break;
    }
  };

  useEffect(() => {
    if (isActive) {
      window.addEventListener("keydown", handleKeyDown);
    } else {
      window.removeEventListener("keydown", handleKeyDown);
    }
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isActive, selectedIndex]);

  return (
    <>
      {adventurers.length > 0 ? (
        <div className="flex basis-2/3">
          <div className="flex flex-col w-1/2 overflow-auto">
            {buttonsData.map((buttonData, index) => (
              <Button
                key={buttonData.id}
                ref={(ref) => (buttonRefs.current[index] = ref)}
                className={
                  selectedIndex === index && isActive ? "animate-pulse" : ""
                }
                variant={
                  selectedIndex === index && isActive ? "default" : "ghost"
                }
                onClick={() => {
                  buttonData.action();
                  setSelectedIndex(index);
                }}
              >
                {buttonData.label}
              </Button>
            ))}
          </div>
          <div className="w-1/2">
            <Info adventurer={adventurers[selectedIndex]} />
          </div>
        </div>
      ) : (
        <p className="text-lg">You do not have any adventurers!</p>
      )}
    </>
  );
};
