import { useState, useEffect, useRef, useCallback } from "react";
import { Button } from "./Button";
import Info from "./Info";
import useAdventurerStore from "../hooks/useAdventurerStore";
import { ButtonData } from "./KeyboardControls";
import { useQueriesStore } from "../hooks/useQueryStore";
import LootIconLoader from "./Loader";

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

  const { data, refetch, isLoading, isDataUpdated } = useQueriesStore();

  const sortedAdventurers = [...adventurers].sort((a, b) => b.level - a.level);

  const filteredAdventurers = showZeroHealth
    ? sortedAdventurers
    : sortedAdventurers.filter((adventurer) => adventurer.health !== 0);

  const DeadIcon = (
    <img className="w-5 h-5" src="/skull.png" alt="Dead Adventurer" />
  );

  const hasDeadAdventurers = sortedAdventurers.some(
    (adventurer) => adventurer.health === 0
  );

  const buttonsData: ButtonData[] = [];
  for (let i = 0; i < adventurers.length; i++) {
    buttonsData.push({
      id: i + 1,
      label: `${adventurers[i].name} - ${adventurers[i].id}`,
      action: () => setAdventurer(adventurers[i]),
      disabled: false,
    });
  }

  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      switch (event.key) {
        case "ArrowUp":
          setSelectedIndex((prev) => Math.max(prev - 1, 0));
          break;
        case "ArrowDown":
          setSelectedIndex((prev) =>
            Math.min(prev + 1, filteredAdventurers.length - 1)
          );
          break;
        case "Enter":
          setAdventurer(filteredAdventurers[selectedIndex]);
          break;
        case "Escape":
          onEscape();
          break;
      }
    },
    [setAdventurer, onEscape, selectedIndex, filteredAdventurers]
  );

  useEffect(() => {
    if (isActive) {
      window.addEventListener("keydown", handleKeyDown);
    } else {
      window.removeEventListener("keydown", handleKeyDown);
    }
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isActive, handleKeyDown]);

  return (
    <>
      {sortedAdventurers.length > 0 ? (
        <div className="flex w-full">
          <div className="flex flex-col w-1/2 sm:w-1/2">
            <div className="flex flex-col overflow-y-auto max-h-screen">
              {" "}
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
                  <div className="flex-grow">{`${adventurer.name} - ${adventurer.id}`}</div>
                  <div className="w-5 text-right">
                    {adventurer.health === 0 ? DeadIcon : null}
                  </div>
                </Button>
              ))}
              {hasDeadAdventurers && (
                <Button onClick={() => setShowZeroHealth(!showZeroHealth)}>
                  {showZeroHealth ? "Hide" : "Show"} dead
                </Button>
              )}
            </div>
          </div>
          {filteredAdventurers.length > 0 && (
            <div className="w-1/2 sm:w-1/2 flex-grow ml-2">
              <Info adventurer={filteredAdventurers[selectedIndex]} />
            </div>
          )}
        </div>
      ) : (
        <p className="text-lg">You do not have any adventurers!</p>
      )}
    </>
  );
};
