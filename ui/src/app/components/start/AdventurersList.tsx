import { useState, useEffect, useRef, useCallback } from "react";
import { Button } from "../buttons/Button";
import Info from "../adventurer/Info";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import { ButtonData } from "../KeyboardControls";
import { Adventurer } from "@/app/types";
import { useMediaQuery } from "react-responsive";
import { SkullIcon } from "../icons/Icons";

export interface AdventurerListProps {
  isActive: boolean;
  onEscape: () => void;
  adventurers: Adventurer[];
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

  const sortedAdventurers = [...adventurers].sort(
    (a, b) => (b.level ?? 0) - (a.level ?? 0)
  );

  const filteredAdventurers = showZeroHealth
    ? sortedAdventurers
    : sortedAdventurers.filter((adventurer) => adventurer.health !== 0);

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
        <div className="flex flex-col gap-2 sm:flex-row w-full h-full items-center sm:items-start">
          {isMobileDevice ? (
            <>
              <div className="flex flex-col w-full sm:w-1/3 sm:h-full overflow-y-auto mx-2 border border-terminal-green">
                {filteredAdventurers.map((adventurer, index) => (
                  <Button
                    key={index}
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
                      {adventurer.health === 0 ? SkullIcon : null}
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
            </>
          ) : (
            <>
              <div className="flex flex-col w-full sm:w-1/3 h-full overflow-y-auto ml-4">
                {filteredAdventurers.map((adventurer, index) => (
                  <Button
                    key={index}
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
                      {adventurer.health === 0 ? <SkullIcon /> : null}
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
                <div className="sm:w-2/12 md:w-6/12 lg:w-2/3 w-full">
                  <Info adventurer={filteredAdventurers[selectedIndex]} />
                </div>
              )}
            </>
          )}
        </div>
      ) : (
        <p className="text-lg uppercase">You do not have any adventurers!</p>
      )}
    </div>
  );
};
