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
  const [showZeroHealth, setShowZeroHealth] = useState(true);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);

  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);

  const sortedAdventurers = [...adventurers].sort((a, b) => b.level - a.level);

  const filteredAdventurers = showZeroHealth
    ? sortedAdventurers
    : sortedAdventurers.filter((adventurer) => adventurer.health !== 0);

  const buttonsData: ButtonData[] = [];
  for (let i = 0; i < sortedAdventurers.length; i++) {
    buttonsData.push({
      id: i + 1,
      label: `${sortedAdventurers[i].name} - ${sortedAdventurers[i].id}`,
      action: () => setAdventurer(sortedAdventurers[i]),
    });
  }

  const DeadIcon = (
    <img className="w-5 h-5" src="/skull.png" alt="Dead Adventurer" />
  );

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
      {sortedAdventurers.length > 0 ? (
        <div className="flex basis-2/3">
          <div className="flex flex-col w-1/2 overflow-auto">
            {filteredAdventurers.map((adventurer, index) => (
              <Button
                key={adventurer.id}
                ref={(ref) => (buttonRefs.current[index] = ref)}
                className={
                  selectedIndex === index && isActive ? "animate-pulse" : ""
                }
                variant={
                  selectedIndex === index && isActive ? "default" : "ghost"
                }
                onClick={() => {
                  setAdventurer(adventurer);
                  setSelectedIndex(index);
                }}
              >
                <div className="flex-grow">
                  {`${adventurer.name} - ${adventurer.id}`}
                </div>
                <span className="flex flex-row">
                  {adventurers[index].health === 0 && DeadIcon}
                </span>
              </Button>
            ))}
          </div>
          <Button onClick={() => setShowZeroHealth(!showZeroHealth)}>
            {showZeroHealth ? "Hide" : "Show"} dead
          </Button>
          <div className="w-1/2">
            <Info adventurer={sortedAdventurers[selectedIndex]} />
          </div>
        </div>
      ) : (
        <p className="text-lg">You do not have any adventurers!</p>
      )}
    </>
  );
};
