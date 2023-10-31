import { useState, useEffect, useRef, useCallback } from "react";
import { Contract } from "starknet";
import { Button } from "@/app/components/buttons/Button";
import Info from "@/app/components/adventurer/Info";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { Adventurer } from "@/app/types";
import { SkullIcon } from "@/app/components/icons/Icons";
import useUIStore from "@/app/hooks/useUIStore";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import LootIconLoader from "@/app/components/icons/Loader";

export interface AdventurerListProps {
  isActive: boolean;
  onEscape: () => void;
  adventurers: Adventurer[];
  handleSwitchAdventurer: (...args: any[]) => any;
  gameContract: Contract;
}

export const AdventurersList = ({
  isActive,
  onEscape,
  adventurers,
  handleSwitchAdventurer,
  gameContract,
}: AdventurerListProps) => {
  const [selectedIndex, setSelectedIndex] = useState(-1);
  const [showZeroHealth, setShowZeroHealth] = useState(true);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);

  const { isLoading } = useQueriesStore();

  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);

  const sortedAdventurers = !isWrongNetwork
    ? [...adventurers].sort((a, b) => (a.level ?? 0) - (b.level ?? 0))
    : [];

  const filteredAdventurers = showZeroHealth
    ? sortedAdventurers
    : sortedAdventurers.filter((adventurer) => adventurer.health !== 0);

  const hasDeadAdventurers = sortedAdventurers.some(
    (adventurer) => adventurer.health === 0
  );

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
    <div className="flex flex-col items-center h-full">
      {sortedAdventurers.length > 0 ? (
        <div className="flex flex-col gap-2 sm:flex-row w-full h-full items-center sm:items-start">
          <div className="flex flex-col w-full sm:w-1/3 overflow-y-auto default-scroll mx-2 border border-terminal-green sm:border-none h-[350px] xl:h-[500px] 2xl:h-[625px] p-1">
            {filteredAdventurers.map((adventurer, index) => (
              <Button
                key={index}
                ref={(ref) => (buttonRefs.current[index] = ref)}
                className={
                  selectedIndex === index && isActive
                    ? "animate-pulse text-lg sm:text-base"
                    : "text-lg sm:text-base"
                }
                variant={
                  selectedIndex === index && isActive ? "default" : "ghost"
                }
                onClick={() => {
                  setAdventurer(adventurer);
                  handleSwitchAdventurer(adventurer.id);
                  setSelectedIndex(index);
                }}
                disabled={adventurer?.health === 0}
              >
                <div className="flex flex-row items-center text-center gap-5">
                  <p>{`${adventurer.name} - ${adventurer.id}`}</p>
                  {adventurer?.health === 0 && (
                    <SkullIcon className="w-3 fill-current" />
                  )}
                </div>
              </Button>
            ))}
          </div>
          <div>
            {hasDeadAdventurers && (
              <Button
                className="w-full h-full"
                size={"xs"}
                onClick={() => setShowZeroHealth(!showZeroHealth)}
              >
                {showZeroHealth ? "Hide" : "Show"} dead
              </Button>
            )}
          </div>
          {filteredAdventurers.length > 0 && (
            <div className="hidden sm:block sm:w-6/12 md:w-6/12 lg:w-2/3 w-full h-full">
              {isLoading.global ? (
                <div className="flex justify-center items-center h-full">
                  <LootIconLoader size="w-10" />
                </div>
              ) : (
                <Info
                  adventurer={filteredAdventurers[selectedIndex]}
                  gameContract={gameContract}
                />
              )}
            </div>
          )}
        </div>
      ) : (
        <p className="text-lg uppercase flex-1">
          You do not have any adventurers!
        </p>
      )}
    </div>
  );
};
