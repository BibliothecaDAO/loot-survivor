import { useState, useEffect, useRef, useCallback } from "react";
import { Button } from "../buttons/Button";
import Info from "../adventurer/Info";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import { ButtonData } from "../KeyboardControls";
import { useQueriesStore } from "../../hooks/useQueryStore";
import { useMediaQuery } from "react-responsive";

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

  const DeadIcon = (
    <img className="w-5 h-5" src="/pixel_skull.png" alt="Dead Adventurer" />
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

  const isMobileDevice = useMediaQuery({
    query: "(max-device-width: 480px)",
  });

  return (
    <div className="flex flex-col h-screen overflow-hidden ">
      {sortedAdventurers.length > 0 ? (
        <div className="flex flex-col gap-2 sm:gap-0 sm:flex-row w-full h-full items-center sm:items-start">
          {isMobileDevice ? (
            <>
              <div className="flex flex-col w-full sm:w-1/3 sm:h-full overflow-y-auto mx-2">
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
              </div>
              <div>
                {hasDeadAdventurers && (
                  <Button onClick={() => setShowZeroHealth(!showZeroHealth)}>
                    {showZeroHealth ? "Hide" : "Show"} dead
                  </Button>
                )}
              </div>
              {filteredAdventurers.length > 0 && (
                <div className="sm:w-2/12 md:w-6/12 lg:w-2/3 w-full sm:ml-2">
                  <Info adventurer={filteredAdventurers[selectedIndex]} />
                </div>
              )}
            </>
          ) : (
            <>
              <div className="flex flex-col w-full sm:w-1/3 h-full overflow-y-auto mx-2">
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
              </div>
              <div>
                {hasDeadAdventurers && (
                  <Button onClick={() => setShowZeroHealth(!showZeroHealth)}>
                    {showZeroHealth ? "Hide" : "Show"} dead
                  </Button>
                )}
              </div>
              {filteredAdventurers.length > 0 && (
                <div className="sm:w-2/12 md:w-6/12 lg:w-2/3 w-full ml-2">
                  <Info adventurer={filteredAdventurers[selectedIndex]} />
                </div>
              )}
            </>
          )}
        </div>
      ) : (
        <p className="text-lg">You do not have any adventurers!</p>
      )}
    </div>
  );
};
